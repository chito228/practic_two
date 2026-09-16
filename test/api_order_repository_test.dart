import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_two/core/api_exceptions.dart';
import 'package:project_two/repositories/api/api_order_repository.dart';

import 'mock_adapter.dart';

void main() {
  late MockAdapter adapter;
  late ApiOrderRepository repo;

  setUp(() {
    adapter = MockAdapter();
    final dio = _buildTestDio(adapter);
    repo = ApiOrderRepository(dio);
  });

  // ─────────────────────────────────────────────────────
  // Тест 5. findByIdWithRelations() — разбор развёрнутого ответа.
  // Проверяем: client, cargo[], routes[] разбираются в OrderFull.
  // ─────────────────────────────────────────────────────
  test('findByIdWithRelations() разбирает client, cargo[], routes[]',
      () async {
    adapter.on(
      'GET',
      '/orders/1',
      statusCode: 200,
      body: {
        'id': 1,
        'orderNumber': 'ORD-001',
        'clientId': 1,
        'client': {'id': 1, 'companyName': 'ООО Логист Транс'},
        'cargoIds': [1, 2],
        'cargo': [
          {'id': 1, 'name': 'Строительные материалы'},
          {'id': 2, 'name': 'Электроника'},
        ],
        'routeIds': [1],
        'routes': [
          {'id': 1, 'name': 'Москва-Санкт-Петербург'},
        ],
        'cargoDescription': 'Строительные материалы',
        'weight': 1500.0,
        'volume': 12.5,
        'shippingDate': '2026-09-01T00:00:00Z',
        'deliveryDate': '2026-09-05T00:00:00Z',
        'status': 'delivered',
        'createdAt': '2026-09-14T00:00:00Z',
        'deletedAt': null,
      },
    );

    final full = await repo.findByIdWithRelations(1);

    expect(full, isNotNull);
    expect(full!.order.orderNumber, 'ORD-001');
    expect(full.client?.companyName, 'ООО Логист Транс');
    expect(full.cargo.length, 2);
    expect(full.cargo[0].name, 'Строительные материалы');
    expect(full.cargo[1].name, 'Электроника');
    expect(full.routes.length, 1);
    expect(full.routes[0].name, 'Москва-Санкт-Петербург');
  });
}

// ─────────────────────────────────────────────────────
// Тот же тестовый Dio, что и в первом файле.
// ─────────────────────────────────────────────────────

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
