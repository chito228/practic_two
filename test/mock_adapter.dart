import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Простой мок-адаптер для Dio.
/// Позволяет задать ответ по ключу "METHOD /path".
class MockAdapter implements HttpClientAdapter {
  final Map<String, MockRoute> _routes = {};

  /// Задать ответ на запрос.
  ///
  /// [method] — HTTP-метод (GET, POST, ...).
  /// [path] — путь, как его передали в `dio.get(path)` — например, `/clients`.
  /// [statusCode] — код ответа.
  /// [body] — тело ответа (будет закодировано в JSON).
  /// [delay] — искусственная задержка (для тестов состояния загрузки).
  /// [error] — тип ошибки Dio (для теста network error). Если задан —
  ///           бросается `DioException` до возврата ответа.
  void on(
    String method,
    String path, {
    required int statusCode,
    Object? body,
    Duration? delay,
    DioExceptionType? error,
  }) {
    _routes['$method $path'] = MockRoute(
      statusCode: statusCode,
      body: body,
      delay: delay,
      error: error,
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    final route = _routes[key];

    if (route == null) {
      throw StateError('Нет мока для запроса: $key');
    }

    if (route.delay != null) {
      await Future.delayed(route.delay!);
    }

    if (route.error != null) {
      throw DioException(
        requestOptions: options,
        type: route.error!,
        error: 'Тестовая сетевая ошибка',
      );
    }

    return ResponseBody.fromString(
      jsonEncode(route.body ?? {}),
      route.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class MockRoute {
  final int statusCode;
  final Object? body;
  final Duration? delay;
  final DioExceptionType? error;

  MockRoute({required this.statusCode, this.body, this.delay, this.error});
}
