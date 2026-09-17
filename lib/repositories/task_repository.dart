import 'package:dio/dio.dart';

import '../models/task.dart';
import '../state/page_result.dart';
import '../state/task_query.dart';

abstract class TaskRepository {
  Future<List<Task>> findAll({bool includeDeleted = false});
  Future<Task?> findById(int id);
  Future<List<Task>> findByCreatedBy(int userId);
  Future<List<Task>> findByAssignedTo(int userId);
  Future<PageResult<Task>> find(
    TaskQuery query, {
    CancelToken? cancelToken,
  });
  Future<Task> create(Task item);
  Future<Task> update(Task item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
