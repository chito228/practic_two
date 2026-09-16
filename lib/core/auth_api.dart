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

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  /// POST /auth/login
  Future<AuthResult> login({
    required String username,
    required String password,
  }) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return _parseAuth(response.data!);
    });
  }

  /// POST /auth/register
  /// Новый пользователь всегда получает роль manager (минимальные права).
  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'email': email,
          'fullName': fullName,
        },
      );
      return AppUser.fromJson(response.data!);
    });
  }

  /// POST /auth/refresh
  Future<AuthResult> refresh(String refreshToken) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return _parseAuth(response.data!);
    });
  }

  /// GET /auth/me
  Future<AppUser> me() {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AppUser.fromJson(response.data!);
    });
  }

  /// POST /auth/logout
  Future<void> logout(String refreshToken) {
    return guard(() async {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    });
  }

  /// GET /users — список пользователей (только admin).
  Future<List<AppUser>> listUsers() {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users',
        queryParameters: {'size': 100},
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AppUser.fromJson)
          .toList();
    });
  }

  /// POST /users — создание пользователя (только admin).
  Future<AppUser> createUser({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required Role role,
  }) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/users',
        data: {
          'username': username,
          'password': password,
          'fullName': fullName,
          'email': email,
          'role': role.toJson(),
        },
      );
      return AppUser.fromJson(response.data!);
    });
  }

  /// PATCH /users/{id} — смена роли или данных (только admin).
  Future<AppUser> updateUser({
    required int id,
    String? fullName,
    String? email,
    String? password,
    Role? role,
  }) {
    return guard(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/users/$id',
        data: {
          if (fullName != null) 'fullName': fullName,
          if (email != null) 'email': email,
          if (password != null) 'password': password,
          if (role != null) 'role': role.toJson(),
        },
      );
      return AppUser.fromJson(response.data!);
    });
  }

  /// DELETE /users/{id} — мягкое удаление (только admin).
  Future<void> deleteUser(int id) {
    return guard(() async {
      await _dio.delete<void>('/users/$id');
    });
  }

  /// Внутренний разбор ответа /auth/login и /auth/refresh.
  AuthResult _parseAuth(Map<String, dynamic> data) {
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access == null || refresh == null) {
      throw const UnauthorizedException('Сервер не вернул токены.');
    }
    return AuthResult(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: data['expiresIn'] as int? ?? 900,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
