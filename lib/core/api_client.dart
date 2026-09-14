import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exceptions.dart';
import 'auth_session.dart';
import 'config.dart';

/// Собирает Dio с интерсепторами: логирование, авторизация,
/// обновление токена, повтор при сетевом сбое.
Dio buildDio(AuthSession session) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      // Не бросать исключение на кодах 4xx — разберём их сами.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = session.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API →] ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API ←] ${response.statusCode} ${response.requestOptions.uri}',
          );
        }
        // Коды 4xx попадают сюда (validateStatus < 500).
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          // Просто throw нельзя: Dio завернёт исключение из интерсептора
          // в DioException с типом unknown, а наш ValidationException
          // окажется спрятан внутри error.
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;

        // 401 на защищённом адресе → пробуем обновить токен и повторить.
        // Условие !path.contains('/auth/') обязательно:
        // без него неудачный логин вызовет refresh, тот вернёт 401,
        // и получится бесконечный цикл.
        if (status == 401 && !path.contains('/auth/')) {
          final ok = await session.refresh(dio);
          if (ok) {
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
            try {
              final response = await dio.fetch(options);
              return handler.resolve(response);
            } on DioException catch (e) {
              return handler.next(e);
            }
          } else {
            session.clear();
          }
        }

        if (kDebugMode) {
          debugPrint('[API ✗] ${error.requestOptions.uri}: ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );

  dio.interceptors.add(RetryInterceptor(dio));

  return dio;
}

/// Повтор только для GET: создание/изменение повторять нельзя
/// (иначе можно случайно создать две записи).
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxAttempts;
  RetryInterceptor(this.dio, {this.maxAttempts = 3});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final method = err.requestOptions.method.toUpperCase();
    final isRead = method == 'GET';
    final isTransient = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode ?? 0) >= 500;

    final attempt = (err.requestOptions.extra['__attempt'] as int?) ?? 0;
    if (!isRead || !isTransient || attempt >= maxAttempts) {
      return handler.next(err);
    }

    // Нарастающая пауза: 300 мс, 600 мс, 1200 мс.
    final delay = Duration(milliseconds: 300 * (1 << attempt));
    await Future.delayed(delay);

    final options = err.requestOptions;
    options.extra['__attempt'] = attempt + 1;
    try {
      final response = await dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
