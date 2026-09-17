import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../models/app_user.dart';
import '../models/role.dart';

/// Центральное хранилище состояния аутентификации.
class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kRole = 'auth_role';

  final SharedPreferences _prefs;
  final AuthApi _api;

  AuthNotifier(this._prefs, this._api);

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _sessionStartedAt;

  String? _logoutReason;

  Duration maxSessionDuration = const Duration(minutes: 60);

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _user != null;

  DateTime? get sessionStartedAt => _sessionStartedAt;
  String? get logoutReason => _logoutReason;

  bool get isSessionExpired {
    final started = _sessionStartedAt;
    if (started == null) return false;
    return DateTime.now().difference(started) > maxSessionDuration;
  }

  Duration? get sessionTimeLeft {
    final started = _sessionStartedAt;
    if (started == null) return null;
    final elapsed = DateTime.now().difference(started);
    final left = maxSessionDuration - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool has(Role role) {
    if (_user == null) return false;
    return _user!.role.level >= role.level;
  }

  bool hasExactly(Role role) => _user?.role == role;

  Role? get effectiveRole {
    const debugKeepRole = bool.fromEnvironment(
      'DEBUG_KEEP_ROLE',
      defaultValue: false,
    );
    if (debugKeepRole) {
      final stored = storedRole;
      if (stored != null) return stored;
    }
    return _user?.role;
  }

  bool uiHas(Role role) {
    final r = effectiveRole;
    if (r == null) return false;
    return r.level >= role.level;
  }

  bool uiHasExactly(Role role) => effectiveRole == role;

  // ─────────────────────────────────────────────
  // UI-хелперы для прав доступа
  // ─────────────────────────────────────────────

  /// Бизнес-разделы могут смотреть admin, manager, logist.
  bool get uiCanViewBusiness =>
      uiHasExactly(Role.admin) ||
      uiHasExactly(Role.manager) ||
      uiHasExactly(Role.logist);

  /// Бизнес-сущности (clients, orders, cargo, routes, vehicles, warehouses)
  /// могут создавать/редактировать logist и admin.
  bool get uiCanEditBusiness =>
      uiHasExactly(Role.logist) || uiHasExactly(Role.admin);

  /// Задачи могут создавать/редактировать manager и admin.
  bool get uiCanEditTasks =>
      uiHasExactly(Role.manager) || uiHasExactly(Role.admin);

  /// Soft-delete («Скрыть») разрешён logist и admin.
  bool get uiCanSoftDelete =>
      uiHasExactly(Role.logist) || uiHasExactly(Role.admin);

  /// Hard-delete («Удалить навсегда») и «Восстановить» — только admin.
  bool get uiCanHardDelete => uiHasExactly(Role.admin);

  // ─────────────────────────────────────────────
  // Восстановление / вход / выход
  // ─────────────────────────────────────────────

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    if (access == null) return;

    _accessToken = access;
    _refreshToken = refresh;
    _sessionStartedAt = DateTime.now();

    try {
      _user = await _api.me();
      await _persistRole();
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          final result = await _api.refresh(refresh);
          _accessToken = result.accessToken;
          _refreshToken = result.refreshToken;
          _user = result.user;
          await _saveTokens();
          await _persistRole();
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } on ApiException {
      // Сервер недоступен.
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username: username, password: password);
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    _sessionStartedAt = DateTime.now();
    _logoutReason = null;
    await _saveTokens();
    await _persistRole();
    notifyListeners();
  }

  void extendSession() {
    if (_user == null) return;
    _sessionStartedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> logout({String? reason}) async {
    _logoutReason = reason;
    final refresh = _refreshToken;
    if (refresh != null) {
      try {
        await _api.logout(refresh);
      } catch (_) {}
    }
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _sessionStartedAt = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kRole);
    notifyListeners();
  }

  String? consumeLogoutReason() {
    final r = _logoutReason;
    _logoutReason = null;
    return r;
  }

  Future<bool> refreshTokens() async {
    final refresh = _refreshToken;
    if (refresh == null) return false;
    try {
      final result = await _api.refresh(refresh);
      _accessToken = result.accessToken;
      _refreshToken = result.refreshToken;
      _user = result.user;
      await _saveTokens();
      await _persistRole();
      notifyListeners();
      return true;
    } catch (_) {
      await logout(reason: 'unauthorized');
      return false;
    }
  }

  Future<void> _saveTokens() async {
    await _prefs.setString(_kAccess, _accessToken ?? '');
    await _prefs.setString(_kRefresh, _refreshToken ?? '');
  }

  Future<void> _persistRole() async {
    final role = _user?.role;
    if (role == null) return;

    const debugKeepRole = bool.fromEnvironment(
      'DEBUG_KEEP_ROLE',
      defaultValue: false,
    );
    if (debugKeepRole && _prefs.getString(_kRole) != null) {
      return;
    }

    await _prefs.setString(_kRole, role.toJson());
  }

  Role? get storedRole {
    final s = _prefs.getString(_kRole);
    if (s == null) return null;
    return Role.fromString(s);
  }

  @visibleForTesting
  void debugSetUser(AppUser user) {
    _user = user;
    _sessionStartedAt = DateTime.now();
    notifyListeners();
  }
}
