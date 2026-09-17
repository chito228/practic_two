import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/driver_license.dart';
import '../driver_license_repository.dart';

class ApiDriverLicenseRepository implements DriverLicenseRepository {
  final Dio _dio;
  ApiDriverLicenseRepository(this._dio);

  static const _path = '/api/collections/driver_licenses/records';

  @override
  Future<List<DriverLicense>> findAll({bool includeDeleted = false}) {
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
          .map(DriverLicense.fromJson)
          .toList();
    });
  }

  @override
  Future<DriverLicense?> findById(String id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
        return DriverLicense.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<DriverLicense?> findByVehicleId(String vehicleId) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: {
          'filter': '(vehicle = "$vehicleId") && (deleted = false)',
          'perPage': 1,
        },
      );
      final items = (response.data!['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(DriverLicense.fromJson)
          .toList();
      return items.isEmpty ? null : items.first;
    });
  }

  /// Создание удостоверения.
  ///
  /// Здесь же — проверка уникальности связи 1:1:
  /// если у машины уже есть удостоверение, кидаем ConflictException.
  /// Это компенсирует отсутствие Unique у Relation-поля в PocketBase.
  @override
  Future<DriverLicense> create(DriverLicense item) {
    return guard(() async {
      final existing = await findByVehicleId(item.vehicleId);
      if (existing != null) {
        throw const ConflictException(
          'У этой машины уже есть водительское удостоверение.',
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        _path,
        data: item.toJson(),
      );
      return DriverLicense.fromJson(response.data!);
    });
  }

  @override
  Future<DriverLicense> update(DriverLicense item) {
    return guard(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_path/${item.id}',
        data: item.toJson(),
      );
      return DriverLicense.fromJson(response.data!);
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
}
