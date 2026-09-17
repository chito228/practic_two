import 'package:dio/dio.dart';

import '../models/app_user.dart';
import '../models/role.dart';
import '../state/page_result.dart';
import '../state/user_query.dart';

abstract class UserRepository {
  Future<List<AppUser>> findAll({bool includeDeleted = false});
  Future<AppUser?> findById(String id);
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
    required String id,
    String? fullName,
    String? email,
    String? password,
    Role? role,
  });
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
