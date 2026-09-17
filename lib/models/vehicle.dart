/// Транспортное средство.
class Vehicle {
  final String id;
  final String plateNumber;
  final String driverName;
  final double capacity;
  final String status;
  final bool isDeleted;

  /// ID водительского удостоверения (связь 1:1).
  /// null, если удостоверения ещё нет.
  final String? licenseId;

  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.driverName,
    required this.capacity,
    required this.status,
    this.isDeleted = false,
    this.licenseId,
  });

  Vehicle copyWith({
    String? id,
    String? plateNumber,
    String? driverName,
    double? capacity,
    String? status,
    bool? isDeleted,
    String? licenseId,
    bool clearLicense = false,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      driverName: driverName ?? this.driverName,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      licenseId: clearLicense ? null : (licenseId ?? this.licenseId),
    );
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String? ?? '',
        plateNumber: json['plateNumber'] as String? ?? '',
        driverName: json['driverName'] as String? ?? '',
        capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'active',
        isDeleted: json['deleted'] as bool? ?? false,
        licenseId: (json['license'] as String?)?.isEmpty == true
            ? null
            : json['license'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'plateNumber': plateNumber,
        'driverName': driverName,
        'capacity': capacity,
        'status': status,
        // 'license' не отправляем — им управляет репозиторий удостоверения.
      };
}
