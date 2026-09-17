import '../models/role.dart';

/// Параметры запроса списка пользователей.
class UserQuery {
  final String search;
  final Role? role;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const UserQuery({
    this.search = '',
    this.role,
    this.sortField = 'username',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  UserQuery copyWith({
    String? search,
    Role? role,
    bool clearRole = false,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return UserQuery(
      search: search ?? this.search,
      role: clearRole ? null : (role ?? this.role),
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  bool get hasFilters =>
      search.isNotEmpty || role != null || includeDeleted;
}
