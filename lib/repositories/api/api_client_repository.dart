import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/client.dart';
import '../client_repository.dart';
import '../../state/client_query.dart';
import '../../state/page_result.dart';

/// Реализация ClientRepository через REST API PocketBase.
///
/// Коллекция: `clients`.
/// Эндпоинты: `/api/collections/clients/records`.
class ApiClientRepository implements ClientRepository {
  final Dio _dio;
  ApiClientRepository(this._dio);

  static const _path = '/api/collections/clients/records';

  @override
  Future<List<Client>> findAll({bool includeDeleted = false}) {
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
          .map(Client.fromJson)
          .toList();
    });
  }

  @override
  Future<Client?> findById(String id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
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
      // PocketBase-фильтр: объединяем soft-delete и поиск.
      final filters = <String>[];
      if (!query.includeDeleted) filters.add('(deleted = false)');

      final search = query.search.trim();
      if (search.isNotEmpty) {
        filters.add(
          '(companyName ~ "${search}" || '
          'contactPerson ~ "${search}" || '
          'email ~ "${search}")',
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
            .map(Client.fromJson)
            .toList(),
        page: data['page'] as int? ?? 1,
        size: data['perPage'] as int? ?? query.size,
        total: data['totalItems'] as int? ?? 0,
      );
    });
  }

  @override
  Future<Client> create(Client item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        _path,
        data: item.toJson(),
      );
      return Client.fromJson(response.data!);
    });
  }

  @override
  Future<Client> update(Client item) {
    return guard(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_path/${item.id}',
        data: item.toJson(),
      );
      return Client.fromJson(response.data!);
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
      // PocketBase не имеет bulk-эндпоинта — делаем цикл.
      for (final id in ids) {
        await _dio.patch<void>('$_path/$id', data: {'deleted': true});
      }
      return ids.length;
    });
  }
}
