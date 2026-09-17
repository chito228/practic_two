/// Параметры запроса списка маршрутов.
class RouteQuery {
  final String search;
  final String? status;
  final int? vehicleId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const RouteQuery({
    this.search = '',
    this.status,
    this.vehicleId,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  RouteQuery copyWith({
    String? search,
    String? status,
    int? vehicleId,
    bool clearStatus = false,
    bool clearVehicle = false,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return RouteQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      vehicleId: clearVehicle ? null : (vehicleId ?? this.vehicleId),
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  bool get hasFilters =>
      search.isNotEmpty ||
      status != null ||
      vehicleId != null ||
      includeDeleted;
}
