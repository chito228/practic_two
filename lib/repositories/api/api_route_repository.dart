import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/route.dart';
import '../route_repository.dart';
import '../../state/route_query.dart';
import '../../state/page_result.dart';

class ApiRouteRepository implements RouteRepository {
  final Dio _dio;
  ApiRouteRepository(this._dio);

  static const _path = '/api/collections/routes/records';

  @override
  Future<List<Route>> findAll({bool includeDeleted = false}) {
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
          .map(Route.fromJson)
          .toList();
    });
  }

  @override
  Future<Route?> findById(String id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
        return Route.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<PageResult<Route>> find(
    RouteQuery query, {
    CancelToken? cancelToken,
  }) {
    return guard(() async {
      final filters = <String>[];
      if (!query.includeDeleted) filters.add('(deleted = false)');
      if (query.status != null) filters.add('(status = "${query.status}")');
      if (query.vehicleId != null) filters.add('(vehicle = "${query.vehicleId}")');

      final search = query.search.trim();
      if (search.isNotEmpty) {
        filters.add(
          '(name ~ "${search}" || origin ~ "${search}" || destination ~ "${search}")',
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
            .map(Route.fromJson)
            .toList(),
        page: data['page'] as int? ?? 1,
        size: data['perPage'] as int? ?? query.size,
        total: data['totalItems'] as int? ?? 0,
      );
    });
  }

  @override
  Future<Route> create(Route item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        _path,
        data: item.toJson(),
      );
      return Route.fromJson(response.data!);
    });
  }

  @override
  Future<Route> update(Route item) {
    return guard(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_path/${item.id}',
        data: item.toJson(),
      );
      return Route.fromJson(response.data!);
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
  Future<List<Route>> findByVehicleId(String vehicleId) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: {
          'filter': '(vehicle = "$vehicleId") && (deleted = false)',
          'perPage': 200,
        },
      );
      return (response.data!['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(Route.fromJson)
          .toList();
    });
  }
}
