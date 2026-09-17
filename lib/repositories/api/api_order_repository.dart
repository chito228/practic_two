import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/order.dart';
import '../../models/client.dart';
import '../../models/cargo.dart';
import '../../models/route.dart' as model;
import '../order_repository.dart';
import '../../state/order_query.dart';
import '../../state/page_result.dart';

class ApiOrderRepository implements OrderRepository {
  final Dio _dio;
  ApiOrderRepository(this._dio);

  static const _path = '/api/collections/orders/records';

  @override
  Future<List<Order>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: {
          'perPage': 200,
          if (!includeDeleted) 'filter': '(deleted = false)',
        },
      );
      return (response.data!['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    });
  }

  @override
  Future<Order?> findById(String id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
        return Order.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<OrderFull?> findByIdWithRelations(String id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          '$_path/$id',
          queryParameters: {'expand': 'client,cargo,routes'},
        );
        final data = response.data!;
        final expand = data['expand'] as Map<String, dynamic>? ?? {};

        return OrderFull(
          order: Order.fromJson(data),
          client: expand['client'] is Map<String, dynamic>
              ? Client.fromJson(expand['client'] as Map<String, dynamic>)
              : null,
          cargo: (expand['cargo'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(Cargo.fromJson)
              .toList(),
          routes: (expand['routes'] as List? ?? [])
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
  Future<PageResult<Order>> find(
    OrderQuery query, {
    CancelToken? cancelToken,
  }) {
    return guard(() async {
      final filters = <String>[];
      if (!query.includeDeleted) filters.add('(deleted = false)');
      if (query.status != null) filters.add('(status = "${query.status}")');
      if (query.clientId != null) filters.add('(client = "${query.clientId}")');
      if (query.cargoId != null) filters.add('(cargo ~ "${query.cargoId}")');
      if (query.routeId != null) filters.add('(routes ~ "${query.routeId}")');
      if (query.dateFrom != null) {
        filters.add(
          '(shippingDate >= "${query.dateFrom!.toIso8601String()}")',
        );
      }
      if (query.dateTo != null) {
        filters.add(
          '(shippingDate <= "${query.dateTo!.toIso8601String()}")',
        );
      }

      final search = query.search.trim();
      if (search.isNotEmpty) {
        filters.add(
          '(orderNumber ~ "${search}" || cargoDescription ~ "${search}")',
        );
      }

      final response = await _dio.get<Map<String, dynamic>>(
        _path,
        cancelToken: cancelToken,
        queryParameters: {
          if (filters.isNotEmpty) 'filter': filters.join(' && '),
          'sort': '${query.sortAscending ? '' : '-'}${query.sortField}',
          'page': query.page,
          'perPage': query.size,
        },
      );
      final data = response.data!;
      return PageResult(
        items: (data['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(Order.fromJson)
            .toList(),
        page: data['page'] as int? ?? 1,
        size: data['perPage'] as int? ?? query.size,
        total: data['totalItems'] as int? ?? 0,
      );
    });
  }

  @override
  Future<Order> create(Order item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        _path,
        data: item.toJson(),
      );
      return Order.fromJson(response.data!);
    });
  }

  @override
  Future<Order> update(Order item) {
    return guard(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_path/${item.id}',
        data: item.toJson(),
      );
      return Order.fromJson(response.data!);
    });
  }

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _dio.patch<void>('$_path/$id', data: {'deleted': true});
    });
  }

  @override
  Future<void> hardDelete(String id) {
    return guard(() async {
      await _dio.delete<void>('$_path/$id');
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _dio.patch<void>('$_path/$id', data: {'deleted': false});
    });
  }

  @override
  Future<int> deleteMany(List<String> ids) {
    return guard(() async {
      for (final id in ids) {
        await _dio.patch<void>('$_path/$id', data: {'deleted': true});
      }
      return ids.length;
    });
  }

  @override
  Future<List<Order>> findByClientId(String clientId) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: {
          'filter': '(client = "$clientId") && (deleted = false)',
          'perPage': 200,
        },
      );
      return (response.data!['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    });
  }
}
