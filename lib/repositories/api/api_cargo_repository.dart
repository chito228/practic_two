import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/cargo.dart';
import '../cargo_repository.dart';

/// Реализация CargoRepository через HTTP API (Dio).
class ApiCargoRepository implements CargoRepository {
  final Dio _dio;
  ApiCargoRepository(this._dio);

  @override
  Future<List<Cargo>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/cargo',
        queryParameters: {
          if (includeDeleted) 'includeDeleted': true,
          'size': 100,
        },
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Cargo.fromJson)
          .toList();
    });
  }

  @override
  Future<Cargo?> findById(int id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/cargo/$id');
        return Cargo.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<Cargo> create(Cargo item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/cargo',
        data: _toApiJson(item),
      );
      return Cargo.fromJson(response.data!);
    });
  }

  @override
  Future<Cargo> update(Cargo item) {
    return guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/cargo/${item.id}',
        data: _toApiJson(item),
      );
      return Cargo.fromJson(response.data!);
    });
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/cargo/$id');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/cargo/$id', queryParameters: {'hard': true});
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post<void>('/cargo/$id/restore');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/cargo/bulk-delete',
        data: {'ids': ids},
      );
      return response.data!['deleted'] as int? ?? 0;
    });
  }

  Map<String, dynamic> _toApiJson(Cargo item) => {
    'name': item.name,
    'description': item.description,
    'weightPerUnit': item.weightPerUnit,
    'volumePerUnit': item.volumePerUnit,
  };
}
