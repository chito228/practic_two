import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../core/auth_api.dart';
import '../../models/app_user.dart';
import '../../models/role.dart';
import '../../state/page_result.dart';
import '../../state/user_query.dart';
import '../user_repository.dart';

/// Реализация UserRepository через AuthApi (Dio).
class ApiUserRepository implements UserRepository {
  final AuthApi _api;
  ApiUserRepository(this._api);

  @override
  Future<List<AppUser>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      final users = await _api.listUsers(includeDeleted: includeDeleted);
      return users;
    });
  }

  @override
  Future<AppUser?> findById(int id) {
    return guard(() async {
      final users = await _api.listUsers(includeDeleted: true);
      try {
        return users.firstWhere((u) => u.id == id);
      } catch (_) {
        return null;
      }
    });
  }

  /// AuthApi не поддерживает серверную фильтрацию,
  /// поэтому фильтруем на клиенте внутри репозитория.
  @override
  Future<PageResult<AppUser>> find(
    UserQuery query, {
    CancelToken? cancelToken,
  }) {
    return guard(() async {
      var rows = await _api.listUsers(includeDeleted: query.includeDeleted);

      // Поиск по ФИО, логину, email.
      if (query.search.trim().isNotEmpty) {
        final needle = query.search.trim().toLowerCase();
        rows = rows
            .where(
              (u) =>
                  u.fullName.toLowerCase().contains(needle) ||
                  u.username.toLowerCase().contains(needle) ||
                  u.email.toLowerCase().contains(needle),
            )
            .toList();
      }

      // Фильтр по роли.
      if (query.role != null) {
        rows = rows.where((u) => u.role == query.role).toList();
      }

      // Сортировка.
      rows.sort((a, b) {
        int result;
        switch (query.sortField) {
          case 'username':
            result = a.username.compareTo(b.username);
            break;
          case 'fullName':
            result = a.fullName.compareTo(b.fullName);
            break;
          case 'email':
            result = a.email.compareTo(b.email);
            break;
          case 'role':
            result = a.role.level.compareTo(b.role.level);
            break;
          default:
            result = a.username.compareTo(b.username);
        }
        return query.sortAscending ? result : -result;
      });

      // Пагинация.
      final total = rows.length;
      final from = (query.page - 1) * query.size;
      final to = (from + query.size) > total ? total : (from + query.size);
      final pageItems = from >= total ? <AppUser>[] : rows.sublist(from, to);

      return PageResult(
        items: pageItems,
        page: query.page,
        size: query.size,
        total: total,
      );
    });
  }

  @override
  Future<AppUser> create({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required Role role,
  }) {
    return guard(() async {
      return _api.createUser(
        username: username,
        password: password,
        fullName: fullName,
        email: email,
        role: role,
      );
    });
  }

  @override
  Future<AppUser> update({
    required int id,
    String? fullName,
    String? email,
    String? password,
    Role? role,
  }) {
    return guard(() async {
      return _api.updateUser(
        id: id,
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
    });
  }

  /// Мягкое удаление — пользователь скрывается.
  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _api.deleteUser(id);
    });
  }

  /// Физическое удаление — запись стирается безвозвратно.
  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _api.hardDeleteUser(id);
    });
  }

  /// Восстановление ранее скрытого пользователя.
  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _api.restoreUser(id);
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      var count = 0;
      for (final id in ids) {
        await _api.deleteUser(id);
        count++;
      }
      return count;
    });
  }
}
