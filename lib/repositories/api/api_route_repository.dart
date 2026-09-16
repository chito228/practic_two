import 'package:dio/dio.dart';
import '../../core/api_exceptions.dart';
import '../../models/route.dart';
import '../route_repository.dart';

/// Реализация RouteRepository через HTTP API (Dio).
class ApiRouteRepository implements RouteRepository {
  final Dio _dio;
  ApiRouteRepository(this._dio);

  @override
  Future<List<Route>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/routes',
        queryParameters: {
          if (includeDeleted) 'includeDeleted': true,
          'size': 100,
        },
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Route.fromJson)
          .toList();
    });
  }

  @override
  Future<Route?> findById(int id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/routes/$id');
        return Route.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<Route> create(Route item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/routes',
        data: _toApiJson(item),
      );
      return Route.fromJson(response.data!);
    });
  }

  @override
  Future<Route> update(Route item) {
    return guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/routes/${item.id}',
        data: _toApiJson(item),
      );
      return Route.fromJson(response.data!);
    });
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/routes/$id');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/routes/$id', queryParameters: {'hard': true});
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post<void>('/routes/$id/restore');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/routes/bulk-delete',
        data: {'ids': ids},
      );
      return response.data!['deleted'] as int? ?? 0;
    });
  }

  @override
  Future<List<Route>> findByVehicleId(int vehicleId) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/routes',
        queryParameters: {
          'vehicleId': vehicleId,
          'size': 100,
        },
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Route.fromJson)
          .toList();
    });
  }

  Map<String, dynamic> _toApiJson(Route item) => {
        'name': item.name,
        'origin': item.origin,
        'destination': item.destination,
        'distance': item.distance,
        'vehicleId': item.vehicleId,
        'estimatedTime': item.estimatedTime,
        'status': item.status,
      };
}
