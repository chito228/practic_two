import 'package:dio/dio.dart';

import '../models/task.dart';
import '../state/task_query.dart';
import '../state/page_result.dart';

abstract class TaskRepository {
  Future<List<Task>> findAll({bool includeDeleted = false});
  Future<Task?> findById(String id);
  Future<List<Task>> findByCreatedBy(String userId);
  Future<List<Task>> findByAssignedTo(String userId);
  Future<PageResult<Task>> find(
    TaskQuery query, {
    CancelToken? cancelToken,
  });
  Future<Task> create(Task item);
  Future<Task> update(Task item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
