import 'package:dio/dio.dart';

import '../models/app_user.dart';
import '../models/role.dart';
import '../state/page_result.dart';
import '../state/user_query.dart';

abstract class UserRepository {
  Future<List<AppUser>> findAll({bool includeDeleted = false});
  Future<AppUser?> findById(int id);
  Future<PageResult<AppUser>> find(
    UserQuery query, {
    CancelToken? cancelToken,
  });
  Future<AppUser> create({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required Role role,
  });
  Future<AppUser> update({
    required int id,
    String? fullName,
    String? email,
    String? password,
    Role? role,
  });
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
