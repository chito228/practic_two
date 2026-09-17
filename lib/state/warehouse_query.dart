/// Параметры запроса списка складов.
class WarehouseQuery {
  final String search;
  final String? type;
  final int? managerId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const WarehouseQuery({
    this.search = '',
    this.type,
    this.managerId,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  WarehouseQuery copyWith({
    String? search,
    String? type,
    int? managerId,
    bool clearType = false,
    bool clearManager = false,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return WarehouseQuery(
      search: search ?? this.search,
      type: clearType ? null : (type ?? this.type),
      managerId: clearManager ? null : (managerId ?? this.managerId),
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  bool get hasFilters =>
      search.isNotEmpty ||
      type != null ||
      managerId != null ||
      includeDeleted;
}
