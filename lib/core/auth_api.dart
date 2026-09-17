import 'package:dio/dio.dart';

import '../models/app_user.dart';
import '../models/role.dart';
import 'api_exceptions.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });
}

/// Обёртка над REST API PocketBase.
///
/// Эндпоинты:
///   POST   /api/collections/users/auth-with-password
///   POST   /api/collections/users/auth-refresh
///   POST   /api/collections/users/auth-refresh/logout
///   GET    /api/collections/users/records
///   POST   /api/collections/users/records
///   PATCH  /api/collections/users/records/{id}
///   DELETE /api/collections/users/records/{id}
class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  static const _usersPath = '/api/collections/users';

  // ─────────────────────────── Авторизация ───────────────────────────

  /// Вход. PocketBase принимает `identity` — это может быть
  /// email или username (мы настроили оба в Identity fields).
  Future<AuthResult> login({
    required String username,
    required String password,
  }) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_usersPath/auth-with-password',
        data: {'identity': username, 'password': password},
      );
      return _parseAuth(response.data!);
    });
  }

  /// Обновление токена. В PocketBase access и refresh — один и тот же
  /// токен, обновляется через `auth-refresh`.
  Future<AuthResult> refresh(String token) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_usersPath/auth-refresh',
        options: Options(headers: {'Authorization': token}),
      );
      return _parseAuth(response.data!);
    });
  }

  /// Текущий пользователь. Вызывается при старте приложения,
  /// чтобы восстановить сессию после перезагрузки вкладки.
  Future<AppUser> me() {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_usersPath/auth-refresh',
      );
      return AppUser.fromJson(
        response.data!['record'] as Map<String, dynamic>,
      );
    });
  }

  /// Выход. В PocketBase достаточно удалить токен на клиенте,
  /// но дёргаем и серверный logout — на всякий случай.
  Future<void> logout(String token) {
    return guard(() async {
      await _dio.post<void>(
        '$_usersPath/auth-refresh/logout',
        options: Options(headers: {'Authorization': token}),
      );
    });
  }

  /// Регистрация. Используется на экране RegisterScreen.
  /// Новый пользователь получает роль manager (минимальные права).
  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_usersPath/records',
        data: {
          'username': username,
          'password': password,
          'passwordConfirm': password,
          'email': email,
          'fullName': fullName,
          'role': 'manager',
        },
      );
      return AppUser.fromJson(response.data!);
    });
  }

  // ─────────────────────── Управление пользователями ─────────────────

  /// Список пользователей.
  ///
  /// [includeDeleted] управляет фильтром:
  ///  - false (по умолчанию) — только активные (`deleted = false`);
  ///  - true — все, включая скрытых.
  Future<List<AppUser>> listUsers({bool includeDeleted = false}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_usersPath/records',
        queryParameters: {
          'perPage': 200,
          if (!includeDeleted) 'filter': '(deleted = false)',
        },
      );
      final data = response.data!;
      return (data['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(AppUser.fromJson)
          .toList();
    });
  }

  /// Создание пользователя (только admin).
  Future<AppUser> createUser({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required Role role,
  }) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_usersPath/records',
        data: {
          'username': username,
          'password': password,
          'passwordConfirm': password,
          'email': email,
          'fullName': fullName,
          'role': role.toJson(),
        },
      );
      return AppUser.fromJson(response.data!);
    });
  }

  /// Редактирование пользователя (только admin).
  Future<AppUser> updateUser({
    required String id,
    String? fullName,
    String? email,
    String? password,
    Role? role,
  }) {
    return guard(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_usersPath/records/$id',
        data: {
          if (fullName != null) 'fullName': fullName,
          if (email != null) 'email': email,
          if (password != null) 'password': password,
          if (password != null) 'passwordConfirm': password,
          if (role != null) 'role': role.toJson(),
        },
      );
      return AppUser.fromJson(response.data!);
    });
  }

  /// Soft-delete: пользователь скрывается, но запись остаётся.
  /// Войти под ним нельзя, но данные не теряются.
  Future<void> softDeleteUser(String id) {
    return guard(() async {
      await _dio.patch<void>(
        '$_usersPath/records/$id',
        data: {'deleted': true},
      );
    });
  }

  /// Восстановление ранее скрытого пользователя.
  Future<void> restoreUser(String id) {
    return guard(() async {
      await _dio.patch<void>(
        '$_usersPath/records/$id',
        data: {'deleted': false},
      );
    });
  }

  /// Физическое удаление пользователя — необратимо.
  /// Используется только для уже скрытых пользователей.
  Future<void> hardDeleteUser(String id) {
    return guard(() async {
      await _dio.delete<void>('$_usersPath/records/$id');
    });
  }

  // ─────────────────────────── Разбор ответа ─────────────────────────

  AuthResult _parseAuth(Map<String, dynamic> data) {
    final token = data['token'] as String?;
    if (token == null) {
      throw const UnauthorizedException('Сервер не вернул токен.');
    }
    return AuthResult(
      accessToken: token,
      // PocketBase не отдаёт отдельный refresh-токен;
      // используем тот же — `auth-refresh` принимает его в заголовке.
      refreshToken: token,
      expiresIn: 3600,
      user: AppUser.fromJson(data['record'] as Map<String, dynamic>),
    );
  }
}
