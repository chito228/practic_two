import 'package:dio/dio.dart';
import 'api_exceptions.dart';

/// Простая сессия: хранит access- и refresh-токен в памяти.
/// В ПР4 логин выполняется программно (вариант A).
/// В ПР5 сюда добавятся роли, restore() и ChangeNotifier.
class AuthSession {
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null;

  /// Программный вход. В ПР5 это заменится на форму входа.
  Future<void> loginWith(
    Dio dio, {
    required String username,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    final data = response.data!;
    _accessToken = data['accessToken'] as String?;
    _refreshToken = data['refreshToken'] as String?;
    if (_accessToken == null) {
      throw const UnauthorizedException('Сервер не вернул токен доступа.');
    }
  }

  /// Обновление пары токенов. Возвращает true, если удалось.
  Future<bool> refresh(Dio dio) async {
    final refresh = _refreshToken;
    if (refresh == null) return false;
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = response.data!;
      _accessToken = data['accessToken'] as String?;
      _refreshToken = data['refreshToken'] as String?;
      return _accessToken != null;
    } on DioException {
      _accessToken = null;
      _refreshToken = null;
      return false;
    }
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
  }
}
