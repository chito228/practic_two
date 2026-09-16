import 'package:dio/dio.dart';
import '../../core/api_exceptions.dart';
import '../../models/client.dart';
import '../client_repository.dart';
import '../../state/client_query.dart';
import '../../state/page_result.dart';

/// Реализация ClientRepository через HTTP API (Dio).
class ApiClientRepository implements ClientRepository {
  final Dio _dio;
  ApiClientRepository(this._dio);

  @override
  Future<List<Client>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/clients',
        queryParameters: {
          if (includeDeleted) 'includeDeleted': true,
          'size': 100,
        },
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Client.fromJson)
          .toList();
    });
  }

  @override
  Future<Client?> findById(int id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/clients/$id');
        return Client.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<PageResult<Client>> find(
    ClientQuery query, {
    CancelToken? cancelToken,
  }) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/clients',
        cancelToken: cancelToken,
        queryParameters: {
          if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
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
            .map(Client.fromJson)
            .toList(),
        page: data['page'] as int? ?? 1,
        size: data['size'] as int? ?? query.size,
        total: data['total'] as int? ?? 0,
      );
    });
  }

  @override
  Future<Client> create(Client item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/clients',
        data: _toApiJson(item),
      );
      return Client.fromJson(response.data!);
    });
  }

  @override
  Future<Client> update(Client item) {
    return guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/clients/${item.id}',
        data: _toApiJson(item),
      );
      return Client.fromJson(response.data!);
    });
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/clients/$id');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/clients/$id', queryParameters: {'hard': true});
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post<void>('/clients/$id/restore');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/clients/bulk-delete',
        data: {'ids': ids},
      );
      return response.data!['deleted'] as int? ?? 0;
    });
  }

  Map<String, dynamic> _toApiJson(Client item) => {
        'companyName': item.companyName,
        'contactPerson': item.contactPerson,
        'phone': item.phone,
        'email': item.email,
        'address': item.address,
      };
}
