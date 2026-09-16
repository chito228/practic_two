import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_two/core/api_exceptions.dart';
import 'package:project_two/models/client.dart';
import 'package:project_two/repositories/api/api_client_repository.dart';
import 'package:project_two/state/client_query.dart';

import 'mock_adapter.dart';

void main() {
  late MockAdapter adapter;
  late ApiClientRepository repo;

  setUp(() {
    adapter = MockAdapter();
    final dio = _buildTestDio(adapter);
    repo = ApiClientRepository(dio);
  });

  // ─────────────────────────────────────────────────────
  // Тест 1. find() — успешный парсинг списка.
  // Проверяем: items, page, size, total разобраны правильно.
  // ─────────────────────────────────────────────────────
  test('find() парсит items, page, size, total', () async {
    adapter.on(
      'GET',
      '/clients',
      statusCode: 200,
      body: {
        'items': [
          {'id': 1, 'companyName': 'ООО Логист Транс'},
          {'id': 2, 'companyName': 'ИП Петров'},
        ],
        'page': 1,
        'size': 10,
        'total': 2,
        'totalPages': 1,
      },
    );

    final result = await repo.find(const ClientQuery());

    expect(result.items.length, 2);
    expect(result.items[0].companyName, 'ООО Логист Транс');
    expect(result.items[1].companyName, 'ИП Петров');
    expect(result.page, 1);
    expect(result.size, 10);
    expect(result.total, 2);
  });

  // ─────────────────────────────────────────────────────
  // Тест 2. findById() → 404 → null.
  // Проверяем: 404 не бросает исключение, возвращает null.
  // ─────────────────────────────────────────────────────
  test('findById() при 404 возвращает null', () async {
    adapter.on(
      'GET',
      '/clients/999',
      statusCode: 404,
      body: {'message': 'Объект не найден'},
    );

    final result = await repo.findById(999);

    expect(result, isNull);
  });

  // ─────────────────────────────────────────────────────
  // Тест 3. create() → 422 → ValidationException.
  // Проверяем: 422 превращается в ValidationException,
  // errors содержит сообщение по полю email.
  // ─────────────────────────────────────────────────────
  test('create() при 422 бросает ValidationException с errors', () async {
    adapter.on(
      'POST',
      '/clients',
      statusCode: 422,
      body: {
        'message': 'Ошибка валидации',
        'errors': {'email': 'Клиент с таким email уже существует'},
      },
    );

    expect(
      () => repo.create(_makeClient()),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.errors['email'],
          'errors[email]',
          'Клиент с таким email уже существует',
        ),
      ),
    );
  });

  // ─────────────────────────────────────────────────────
  // Тест 4. Сетевая ошибка → NetworkException.
  // Проверяем: DioException(connectionError) превращается
  // в NetworkException.
  // ─────────────────────────────────────────────────────
  test('при сетевой ошибке бросает NetworkException', () async {
    adapter.on(
      'GET',
      '/clients',
      statusCode: 0,
      error: DioExceptionType.connectionError,
    );

    expect(
      () => repo.find(const ClientQuery()),
      throwsA(isA<NetworkException>()),
    );
  });
}

// ─────────────────────────────────────────────────────
// Вспомогательные функции
// ─────────────────────────────────────────────────────

/// Тестовый Dio — минимум интерсепторов:
/// только превращение 4xx в DioException с доменной ошибкой.
/// Без retry и без auth — чтобы тесты были быстрыми и изолированными.
Dio _buildTestDio(MockAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8080/api',
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = adapter;

  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
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
    ),
  );

  return dio;
}

Client _makeClient() => Client(
  id: 0,
  companyName: 'Тестовая компания',
  contactPerson: 'Тестовый Тест',
  phone: '+7-999-000-00-00',
  email: 'test@example.com',
  orderIds: const [],
);
