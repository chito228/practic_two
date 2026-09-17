/// Тип склада.
enum WarehouseType {
  dry('Сухой'),
  cold('Холодный'),
  hazardous('Опасные грузы');

  final String label;
  const WarehouseType(this.label);

  static WarehouseType fromString(String? value) {
    switch (value) {
      case 'cold':
        return WarehouseType.cold;
      case 'hazardous':
        return WarehouseType.hazardous;
      default:
        return WarehouseType.dry;
    }
  }

  String toJson() => name;
}

class Warehouse {
  final int id;
  final String name;
  final String address;
  final WarehouseType type;
  final double capacity;
  final double currentLoad;
  final int? managerId;
  final List<int> cargoIds;
  final List<int> routeIds;
  final DateTime? deletedAt;

  const Warehouse({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.capacity,
    required this.currentLoad,
    this.managerId,
    required this.cargoIds,
    required this.routeIds,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  /// Процент заполненности.
  double get fillPercent =>
      capacity > 0 ? (currentLoad / capacity * 100) : 0;

  /// Переполнен ли склад.
  bool get isOverloaded => currentLoad > capacity;

  /// Критическая заполненность (>= 90%).
  bool get isCritical => !isOverloaded && fillPercent >= 90;

  Warehouse copyWith({
    int? id,
    String? name,
    String? address,
    WarehouseType? type,
    double? capacity,
    double? currentLoad,
    int? managerId,
    bool clearManager = false,
    List<int>? cargoIds,
    List<int>? routeIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      currentLoad: currentLoad ?? this.currentLoad,
      managerId: clearManager ? null : (managerId ?? this.managerId),
      cargoIds: cargoIds ?? this.cargoIds,
      routeIds: routeIds ?? this.routeIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'type': type.toJson(),
    'capacity': capacity,
    'currentLoad': currentLoad,
    'managerId': managerId,
    'cargoIds': cargoIds,
    'routeIds': routeIds,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    type: WarehouseType.fromString(json['type'] as String?),
    capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
    currentLoad: (json['currentLoad'] as num?)?.toDouble() ?? 0.0,
    managerId: json['managerId'] as int?,
    cargoIds: (json['cargoIds'] as List?)?.cast<int>() ?? [],
    routeIds: (json['routeIds'] as List?)?.cast<int>() ?? [],
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
  );
}
