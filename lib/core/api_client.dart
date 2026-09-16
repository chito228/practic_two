import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

/// Собирает Dio с интерсепторами: логирование, авторизация,
/// обновление токена, повтор при сетевом сбое.
///
/// Не знает про AuthNotifier напрямую — принимает колбэки:
/// - [tokenProvider] — отдаёт текущий accessToken (или null).
/// - [onRefresh] — вызывает refresh; true, если удалось.
/// - [onUnauthorized] — вызывается на 401 после неудачного refresh.
Dio buildDio({
  String? Function()? tokenProvider,
  Future<bool> Function()? onRefresh,
  void Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
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
        final status = response.statusCode ?? 0;
        if (status >= 400) {
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

        // 401 на защищённом адресе → пробуем refresh и повтор.
        // Условие !path.contains('/auth/') обязательно: без него
        // неудачный логин вызовет refresh, тот вернёт 401 — цикл.
        if (status == 401 && !path.contains('/auth/')) {
          if (onRefresh != null) {
            final ok = await onRefresh();
            if (ok) {
              try {
                final options = error.requestOptions;
                final freshToken = tokenProvider?.call();
                if (freshToken != null) {
                  options.headers['Authorization'] = 'Bearer $freshToken';
                }
                final response = await dio.fetch(options);
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
          }
          onUnauthorized?.call();
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
    final isTransient =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode ?? 0) >= 500;

    final attempt = (err.requestOptions.extra['__attempt'] as int?) ?? 0;
    if (!isRead || !isTransient || attempt >= maxAttempts) {
      return handler.next(err);
    }

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
