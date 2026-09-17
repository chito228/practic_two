/// Параметры запроса списка транспорта.
class VehicleQuery {
  final String search;
  final String? status;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const VehicleQuery({
    this.search = '',
    this.status,
    this.sortField = 'plateNumber',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  VehicleQuery copyWith({
    String? search,
    String? status,
    bool clearStatus = false,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return VehicleQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  bool get hasFilters =>
      search.isNotEmpty || status != null || includeDeleted;
}
