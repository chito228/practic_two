class DriverLicense {
  final int id;
  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final int vehicleId;
  final DateTime? deletedAt;

  const DriverLicense({
    required this.id,
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
    required this.vehicleId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  DriverLicense copyWith({
    int? id,
    String? number,
    DateTime? issuedAt,
    DateTime? expiresAt,
    int? vehicleId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return DriverLicense(
      id: id ?? this.id,
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      vehicleId: vehicleId ?? this.vehicleId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'vehicleId': vehicleId,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory DriverLicense.fromJson(Map<String, dynamic> json) => DriverLicense(
        id: json['id'] as int? ?? 0,
        number: json['number'] as String? ?? '',
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        vehicleId: json['vehicleId'] as int? ?? 0,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}

class Vehicle {
  final int id;
  final String plateNumber;
  final String driverName;
  final double capacity;
  final String status;
  final DriverLicense? driverLicense;
  final List<int> routeIds;
  final DateTime? deletedAt;

  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.driverName,
    required this.capacity,
    required this.status,
    this.driverLicense,
    required this.routeIds,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get hasLicense => driverLicense != null;

  Vehicle copyWith({
    int? id,
    String? plateNumber,
    String? driverName,
    double? capacity,
    String? status,
    DriverLicense? driverLicense,
    List<int>? routeIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      driverName: driverName ?? this.driverName,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      driverLicense: driverLicense ?? this.driverLicense,
      routeIds: routeIds ?? this.routeIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plateNumber': plateNumber,
        'driverName': driverName,
        'capacity': capacity,
        'status': status,
        'driverLicense': driverLicense?.toJson(),
        'routeIds': routeIds,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as int? ?? 0,
        plateNumber: json['plateNumber'] as String? ?? '',
        driverName: json['driverName'] as String? ?? '',
        capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'active',
        driverLicense: json['driverLicense'] == null
            ? null
            : DriverLicense.fromJson(json['driverLicense'] as Map<String, dynamic>),
        routeIds: (json['routeIds'] as List?)?.cast<int>() ?? [],
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
