import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../core/auth_api.dart';
import '../../models/app_user.dart';
import '../../models/role.dart';
import '../../state/page_result.dart';
import '../../state/user_query.dart';
import '../user_repository.dart';

/// Реализация UserRepository через AuthApi (Dio → PocketBase).
///
/// Серверная фильтрация по роли и поиску в PocketBase
/// для `users` не поддерживается «из коробки» через простые
/// query-параметры, поэтому фильтруем на клиенте после загрузки.
class ApiUserRepository implements UserRepository {
  final AuthApi _api;
  ApiUserRepository(this._api);

  @override
  Future<List<AppUser>> findAll({bool includeDeleted = false}) {
    return guard(() async {
      return _api.listUsers(includeDeleted: includeDeleted);
    });
  }

  @override
  Future<AppUser?> findById(String id) {
    return guard(() async {
      // Загружаем все (включая скрытых), чтобы уметь показать
      // запись даже если она скрыта.
      final users = await _api.listUsers(includeDeleted: true);
      try {
        return users.firstWhere((u) => u.id == id);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<PageResult<AppUser>> find(
    UserQuery query, {
    CancelToken? cancelToken,
  }) {
    return guard(() async {
      // Забираем всех (или только активных), а фильтрацию/сортировку/
      // пагинацию делаем на клиенте.
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
    required String id,
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

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _api.softDeleteUser(id);
    });
  }

  @override
  Future<void> hardDelete(String id) {
    return guard(() async {
      await _api.hardDeleteUser(id);
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _api.restoreUser(id);
    });
  }

  @override
  Future<int> deleteMany(List<String> ids) {
    return guard(() async {
      var count = 0;
      for (final id in ids) {
        await _api.softDeleteUser(id);
        count++;
      }
      return count;
    });
  }
}
