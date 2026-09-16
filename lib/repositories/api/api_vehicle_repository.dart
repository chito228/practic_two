import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/vehicle.dart';
import '../vehicle_repository.dart';

/// Реализация VehicleRepository через HTTP API (Dio).
class ApiVehicleRepository implements VehicleRepository {
  final Dio _dio;
  ApiVehicleRepository(this._dio);

  @override
  Future<List<Vehicle>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vehicles',
        queryParameters: {
          if (includeDeleted) 'includeDeleted': true,
          'size': 100,
        },
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Vehicle.fromJson)
          .toList();
    });
  }

  @override
  Future<Vehicle?> findById(int id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/vehicles/$id');
        return Vehicle.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<Vehicle> create(Vehicle item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/vehicles',
        data: _toApiJson(item),
      );
      return Vehicle.fromJson(response.data!);
    });
  }

  @override
  Future<Vehicle> update(Vehicle item) {
    return guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/vehicles/${item.id}',
        data: _toApiJson(item),
      );
      return Vehicle.fromJson(response.data!);
    });
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/vehicles/$id');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/vehicles/$id', queryParameters: {'hard': true});
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post<void>('/vehicles/$id/restore');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/vehicles/bulk-delete',
        data: {'ids': ids},
      );
      return response.data!['deleted'] as int? ?? 0;
    });
  }

  /// `driverLicense` сервер принимает как объект или null.
  /// В учебном сценарии лицензия редко редактируется из формы,
  /// поэтому шлём как есть — или null, если нет.
  Map<String, dynamic> _toApiJson(Vehicle item) => {
    'plateNumber': item.plateNumber,
    'driverName': item.driverName,
    'capacity': item.capacity,
    'status': item.status,
    'driverLicense': item.driverLicense?.toJson(),
  };
}
