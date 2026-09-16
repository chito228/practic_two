class OrderQuery {
  final String search;
  final String? status;
  final int? clientId;
  final int? cargoId;
  final int? routeId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const OrderQuery({
    this.search = '',
    this.status,
    this.clientId,
    this.cargoId,
    this.routeId,
    this.dateFrom,
    this.dateTo,
    this.sortField = 'orderNumber',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  OrderQuery copyWith({
    String? search,
    String? status,
    int? clientId,
    int? cargoId,
    int? routeId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return OrderQuery(
      search: search ?? this.search,
      status: status ?? this.status,
      clientId: clientId ?? this.clientId,
      cargoId: cargoId ?? this.cargoId,
      routeId: routeId ?? this.routeId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
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
      clientId != null ||
      cargoId != null ||
      routeId != null ||
      dateFrom != null ||
      dateTo != null ||
      includeDeleted;
}
