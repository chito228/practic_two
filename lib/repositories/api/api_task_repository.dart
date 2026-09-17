import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/task.dart';
import '../task_repository.dart';
import '../../state/task_query.dart';
import '../../state/page_result.dart';

class ApiTaskRepository implements TaskRepository {
  final Dio _dio;
  ApiTaskRepository(this._dio);

  static const _path = '/api/collections/tasks/records';

  @override
  Future<List<Task>> findAll({bool includeDeleted = false}) {
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
          .map(Task.fromJson)
          .toList();
    });
  }

  @override
  Future<Task?> findById(String id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
        return Task.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<List<Task>> findByCreatedBy(String userId) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: {
          'filter': '(createdBy = "$userId") && (deleted = false)',
          'perPage': 200,
        },
      );
      return (response.data!['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
    });
  }

  @override
  Future<List<Task>> findByAssignedTo(String userId) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: {
          'filter': '(assignedTo = "$userId") && (deleted = false)',
          'perPage': 200,
        },
      );
      return (response.data!['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
    });
  }

  @override
  Future<PageResult<Task>> find(
    TaskQuery query, {
    CancelToken? cancelToken,
  }) {
    return guard(() async {
      final filters = <String>[];
      if (!query.includeDeleted) filters.add('(deleted = false)');
      if (query.status != null) filters.add('(status = "${query.status}")');
      if (query.priority != null) {
        filters.add('(priority = "${query.priority}")');
      }
      if (query.createdById != null) {
        filters.add('(createdBy = "${query.createdById}")');
      }
      if (query.assignedToId != null) {
        filters.add('(assignedTo = "${query.assignedToId}")');
      }

      final search = query.search.trim();
      if (search.isNotEmpty) {
        filters.add('(title ~ "${search}" || description ~ "${search}")');
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
            .map(Task.fromJson)
            .toList(),
        page: data['page'] as int? ?? 1,
        size: data['perPage'] as int? ?? query.size,
        total: data['totalItems'] as int? ?? 0,
      );
    });
  }

  @override
  Future<Task> create(Task item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        _path,
        data: item.toJson(),
      );
      return Task.fromJson(response.data!);
    });
  }

  @override
  Future<Task> update(Task item) {
    return guard(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_path/${item.id}',
        data: item.toJson(),
      );
      return Task.fromJson(response.data!);
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
