import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/task.dart';
import '../../state/page_result.dart';
import '../../state/task_query.dart';
import '../task_repository.dart';

class ApiTaskRepository implements TaskRepository {
  final Dio _dio;
  ApiTaskRepository(this._dio);

  @override
  Future<List<Task>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tasks',
        queryParameters: {
          if (includeDeleted) 'includeDeleted': true,
          'size': 100,
        },
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
    });
  }

  @override
  Future<Task?> findById(int id) {
    return guard(() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/tasks/$id');
        return Task.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  @override
  Future<List<Task>> findByCreatedBy(int userId) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tasks',
        queryParameters: {'createdById': userId, 'size': 100},
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
    });
  }

  @override
  Future<List<Task>> findByAssignedTo(int userId) {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tasks',
        queryParameters: {'assignedToId': userId, 'size': 100},
      );
      final data = response.data!;
      return (data['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
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
      final response = await _dio.get<Map<String, dynamic>>(
        '/tasks',
        cancelToken: cancelToken,
        queryParameters: {
          if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
          if (query.status != null) 'status': query.status,
          if (query.priority != null) 'priority': query.priority,
          if (query.createdById != null) 'createdById': query.createdById,
          if (query.assignedToId != null) 'assignedToId': query.assignedToId,
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
            .map(Task.fromJson)
            .toList(),
        page: data['page'] as int? ?? 1,
        size: data['size'] as int? ?? query.size,
        total: data['total'] as int? ?? 0,
      );
    });
  }

  @override
  Future<Task> create(Task item) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/tasks',
        data: _toApiJson(item),
      );
      return Task.fromJson(response.data!);
    });
  }

  @override
  Future<Task> update(Task item) {
    return guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/tasks/${item.id}',
        data: _toApiJson(item),
      );
      return Task.fromJson(response.data!);
    });
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete<void>('/tasks/$id');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete<void>(
        '/tasks/$id',
        queryParameters: {'hard': true},
      );
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post<void>('/tasks/$id/restore');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/tasks/bulk-delete',
        data: {'ids': ids},
      );
      return response.data!['deleted'] as int? ?? 0;
    });
  }

  Map<String, dynamic> _toApiJson(Task item) => {
    'title': item.title,
    'description': item.description,
    'priority': item.priority.toJson(),
    'status': item.status.toJson(),
    'createdById': item.createdById,
    'assignedToId': item.assignedToId,
    'orderId': item.orderId,
    'routeId': item.routeId,
    'createdAt': item.createdAt.toIso8601String(),
    'dueDate': item.dueDate?.toIso8601String(),
    'resolution': item.resolution,
  };
}
