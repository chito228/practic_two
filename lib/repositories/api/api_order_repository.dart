import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/order.dart';
import '../../models/client.dart';
import '../../models/cargo.dart';
import '../../models/route.dart' as model;
import '../order_repository.dart';
import '../../state/order_query.dart';
import '../../state/page_result.dart';

/// Реализация OrderRepository через HTTP API (Dio).
class ApiOrderRepository implements OrderRepository {
  final Dio _dio;
  ApiOrderRepository(this._dio);

  @override
  Future<List<Order>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/orders',
        queryParameters: {
          if (includeDeleted) 'includeDeleted': true,
          'size': 100,
        },
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    });
  }

  @override
  Future<Order?> findById(int id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/orders/$id');
        return Order.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  /// Один HTTP-запрос GET /orders/{id}.
  /// Сервер в ответе уже отдаёт развёрнутые client, cargo[], routes[].
  @override
  Future<OrderFull?> findByIdWithRelations(int id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/orders/$id');
        final data = response.data!;

        return OrderFull(
          order: Order.fromJson(data),
          client: data['client'] is Map<String, dynamic>
              ? Client.fromJson(data['client'] as Map<String, dynamic>)
              : null,
          cargo: (data['cargo'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(Cargo.fromJson)
              .toList(),
          routes: (data['routes'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map((e) => model.Route.fromJson(e))
              .toList(),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<PageResult<Order>> find(OrderQuery query, {CancelToken? cancelToken}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/orders',
        cancelToken: cancelToken,
        queryParameters: {
          if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
          if (query.status != null) 'status': query.status,
          if (query.clientId != null) 'clientId': query.clientId,
          if (query.cargoId != null) 'cargoId': query.cargoId,
          if (query.routeId != null) 'routeId': query.routeId,
          if (query.dateFrom != null)
            'dateFrom': query.dateFrom!.toIso8601String(),
          if (query.dateTo != null) 'dateTo': query.dateTo!.toIso8601String(),
          'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
          'page': query.page,
          'size': query.size,
          if (query.includeDeleted) 'includeDeleted': true,
        },
      );
      final data = response.data!;
      return PageResult(
        items: (data['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Order.fromJson)
            .toList(),
        page: data['page'] as int? ?? 1,
        size: data['size'] as int? ?? query.size,
        total: data['total'] as int? ?? 0,
      );
    });
  }

  @override
  Future<Order> create(Order item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: _toApiJson(item),
      );
      return Order.fromJson(response.data!);
    });
  }

  @override
  Future<Order> update(Order item) {
    return guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/orders/${item.id}',
        data: _toApiJson(item),
      );
      return Order.fromJson(response.data!);
    });
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/orders/$id');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/orders/$id', queryParameters: {'hard': true});
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post<void>('/orders/$id/restore');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/bulk-delete',
        data: {'ids': ids},
      );
      return response.data!['deleted'] as int? ?? 0;
    });
  }

  @override
  Future<List<Order>> findByClientId(int clientId) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/orders',
        queryParameters: {'clientId': clientId, 'size': 100},
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    });
  }

  Map<String, dynamic> _toApiJson(Order item) => {
    'orderNumber': item.orderNumber,
    'clientId': item.clientId,
    'cargoIds': item.cargoIds,
    'routeIds': item.routeIds,
    'cargoDescription': item.cargoDescription,
    'weight': item.weight,
    'volume': item.volume,
    'shippingDate': item.shippingDate.toIso8601String(),
    'deliveryDate': item.deliveryDate?.toIso8601String(),
    'status': item.status,
  };
}
