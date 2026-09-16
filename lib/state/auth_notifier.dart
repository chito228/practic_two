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

  /// Причина последнего выхода. Используется на LoginScreen,
  /// чтобы показать пользователю понятное сообщение.
  ///   - null         — обычный выход (сообщение не нужно)
  ///   - 'session'    — истекла общая длительность сессии
  ///   - 'inactivity' — долго не было действий
  ///   - 'unauthorized' — токен отклонён сервером
  String? _logoutReason;

  /// Максимальная длительность сессии. По умолчанию — 60 минут.
  /// ИЗМЕНЕНИЕ: было seconds: 90, исправлено на minutes: 60 в соответствии с комментарием.
  Duration maxSessionDuration = const Duration(minutes: 60);
  
  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _user != null;

  DateTime? get sessionStartedAt => _sessionStartedAt;
  String? get logoutReason => _logoutReason;

  /// Истекла ли общая длительность сессии.
  bool get isSessionExpired {
    final started = _sessionStartedAt;
    if (started == null) return false;
    return DateTime.now().difference(started) > maxSessionDuration;
  }

  /// Сколько осталось до истечения сессии.
  /// null, если сессия не начата.
  Duration? get sessionTimeLeft {
    final started = _sessionStartedAt;
    if (started == null) return null;
    final elapsed = DateTime.now().difference(started);
    final left = maxSessionDuration - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// Реальная проверка прав (используется в роутере и на сервере).
  bool has(Role role) {
    if (_user == null) return false;
    return _user!.role.level >= role.level;
  }

  bool hasExactly(Role role) => _user?.role == role;

  /// Роль для отображения UI.
  /// В обычном режиме — из токена (user.role).
  /// В debug-режиме (--dart-define=DEBUG_KEEP_ROLE=true) — из localStorage.
  Role? get effectiveRole {
    const debugKeepRole =
        bool.fromEnvironment('DEBUG_KEEP_ROLE', defaultValue: false);
    if (debugKeepRole) {
      final stored = storedRole;
      if (stored != null) return stored;
    }
    return _user?.role;
  }

  /// Проверка прав для UI (использует effectiveRole).
  bool uiHas(Role role) {
    final r = effectiveRole;
    if (r == null) return false;
    return r.level >= role.level;
  }

  bool uiHasExactly(Role role) => effectiveRole == role;

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

  /// Продлить сессию: сбросить отсчёт длительности.
  /// Используется в диалоге «Сессия скоро истечёт».
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

  /// Возвращает причину выхода и сбрасывает её.
  /// Используется LoginScreen.
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

  /// Сохраняем роль в localStorage.
  ///
  /// В обычном режиме — всегда пишем актуальную роль из токена.
  /// В debug-режиме (--dart-define=DEBUG_KEEP_ROLE=true) — НЕ перезаписываем
  /// уже существующее значение (для демонстрации пункта 17 ПР5).
  Future<void> _persistRole() async {
    final role = _user?.role;
    if (role == null) return;

    const debugKeepRole =
        bool.fromEnvironment('DEBUG_KEEP_ROLE', defaultValue: false);
    if (debugKeepRole && _prefs.getString(_kRole) != null) {
      return;
    }

    await _prefs.setString(_kRole, role.toJson());
  }

  /// Читает сохранённую роль из localStorage.
  Role? get storedRole {
    final s = _prefs.getString(_kRole);
    if (s == null) return null;
    return Role.fromString(s);
  }

  // ─────────────────────────────────────────────
  // ТОЛЬКО ДЛЯ ТЕСТОВ
  // ─────────────────────────────────────────────

  @visibleForTesting
  void debugSetUser(AppUser user) {
    _user = user;
    _sessionStartedAt = DateTime.now();
    notifyListeners();
  }
}
