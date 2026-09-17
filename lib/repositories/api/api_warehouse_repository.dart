import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/warehouse.dart';
import '../../state/page_result.dart';
import '../../state/warehouse_query.dart';
import '../warehouse_repository.dart';

class ApiWarehouseRepository implements WarehouseRepository {
  final Dio _dio;
  ApiWarehouseRepository(this._dio);

  @override
  Future<List<Warehouse>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/warehouses',
        queryParameters: {
          if (includeDeleted) 'includeDeleted': true,
          'size': 100,
        },
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Warehouse.fromJson)
          .toList();
    });
  }

  @override
  Future<Warehouse?> findById(int id) {
    return guard(() async {
      try {
        final response =
            await _dio.get<Map<String, dynamic>>('/warehouses/$id');
        return Warehouse.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<PageResult<Warehouse>> find(
    WarehouseQuery query, {
    CancelToken? cancelToken,
  }) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/warehouses',
        cancelToken: cancelToken,
        queryParameters: {
          if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
          if (query.type != null) 'type': query.type,
          if (query.managerId != null) 'managerId': query.managerId,
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
            .map(Warehouse.fromJson)
            .toList(),
        page: data['page'] as int? ?? 1,
        size: data['size'] as int? ?? query.size,
        total: data['total'] as int? ?? 0,
      );
    });
  }

  @override
  Future<Warehouse> create(Warehouse item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/warehouses',
        data: _toApiJson(item),
      );
      return Warehouse.fromJson(response.data!);
    });
  }

  @override
  Future<Warehouse> update(Warehouse item) {
    return guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/warehouses/${item.id}',
        data: _toApiJson(item),
      );
      return Warehouse.fromJson(response.data!);
    });
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/warehouses/$id');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete<void>(
        '/warehouses/$id',
        queryParameters: {'hard': true},
      );
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post<void>('/warehouses/$id/restore');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/warehouses/bulk-delete',
        data: {'ids': ids},
      );
      return response.data!['deleted'] as int? ?? 0;
    });
  }

  Map<String, dynamic> _toApiJson(Warehouse item) => {
    'name': item.name,
    'address': item.address,
    'type': item.type.toJson(),
    'capacity': item.capacity,
    'currentLoad': item.currentLoad,
    'managerId': item.managerId,
    'cargoIds': item.cargoIds,
    'routeIds': item.routeIds,
  };
}
