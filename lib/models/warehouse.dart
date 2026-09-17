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
  final String id;
  final String name;
  final String address;
  final WarehouseType type;
  final double capacity;
  final double currentLoad;
  final String? managerId;
  final List<String> cargoIds;
  final List<String> routeIds;
  final bool isDeleted;

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
    this.isDeleted = false,
  });

  double get fillPercent =>
      capacity > 0 ? (currentLoad / capacity * 100) : 0;

  bool get isOverloaded => currentLoad > capacity;

  bool get isCritical => !isOverloaded && fillPercent >= 90;

  Warehouse copyWith({
    String? id,
    String? name,
    String? address,
    WarehouseType? type,
    double? capacity,
    double? currentLoad,
    String? managerId,
    List<String>? cargoIds,
    List<String>? routeIds,
    bool? isDeleted,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      currentLoad: currentLoad ?? this.currentLoad,
      managerId: managerId ?? this.managerId,
      cargoIds: cargoIds ?? this.cargoIds,
      routeIds: routeIds ?? this.routeIds,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    type: WarehouseType.fromString(json['type'] as String?),
    capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
    currentLoad: (json['currentLoad'] as num?)?.toDouble() ?? 0.0,
    managerId: json['manager'] as String?,
    cargoIds: (json['cargo'] as List?)?.cast<String>() ?? const [],
    routeIds: (json['routes'] as List?)?.cast<String>() ?? const [],
    isDeleted: json['deleted'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'type': type.toJson(),
    'capacity': capacity,
    'currentLoad': currentLoad,
    'manager': managerId,
    'cargo': cargoIds,
    'routes': routeIds,
  };
}
