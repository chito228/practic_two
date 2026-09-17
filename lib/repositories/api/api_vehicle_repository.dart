import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/vehicle.dart';
import '../vehicle_repository.dart';
import '../../state/vehicle_query.dart';
import '../../state/page_result.dart';

class ApiVehicleRepository implements VehicleRepository {
  final Dio _dio;
  ApiVehicleRepository(this._dio);

  static const _path = '/api/collections/vehicles/records';

  @override
  Future<List<Vehicle>> findAll({bool includeDeleted = false}) {
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
          .map(Vehicle.fromJson)
          .toList();
    });
  }

  @override
  Future<Vehicle?> findById(String id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
        return Vehicle.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<PageResult<Vehicle>> find(
    VehicleQuery query, {
    CancelToken? cancelToken,
  }) {
    return guard(() async {
      final filters = <String>[];
      if (!query.includeDeleted) filters.add('(deleted = false)');
      if (query.status != null) filters.add('(status = "${query.status}")');

      final search = query.search.trim();
      if (search.isNotEmpty) {
        filters.add('(plateNumber ~ "${search}" || driverName ~ "${search}")');
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
            .map(Vehicle.fromJson)
            .toList(),
        page: data['page'] as int? ?? 1,
        size: data['perPage'] as int? ?? query.size,
        total: data['totalItems'] as int? ?? 0,
      );
    });
  }

  @override
  Future<Vehicle> create(Vehicle item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        _path,
        data: item.toJson(),
      );
      return Vehicle.fromJson(response.data!);
    });
  }

  @override
  Future<Vehicle> update(Vehicle item) {
    return guard(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_path/${item.id}',
        data: item.toJson(),
      );
      return Vehicle.fromJson(response.data!);
    });
  }

  @override
  Future<Vehicle> updateStatus(String id, String status) {
    return guard(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_path/$id',
        data: {'status': status},
      );
      return Vehicle.fromJson(response.data!);
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
}
