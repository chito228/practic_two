class Route {
  final int id;
  final String name;
  final String origin;
  final String destination;
  final double distance;
  final int vehicleId;
  final double estimatedTime;
  final String status;
  final List<int> orderIds;
  final DateTime? deletedAt;

  const Route({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.distance,
    required this.vehicleId,
    required this.estimatedTime,
    required this.status,
    required this.orderIds,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Route copyWith({
    int? id,
    String? name,
    String? origin,
    String? destination,
    double? distance,
    int? vehicleId,
    double? estimatedTime,
    String? status,
    List<int>? orderIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Route(
      id: id ?? this.id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      distance: distance ?? this.distance,
      vehicleId: vehicleId ?? this.vehicleId,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      status: status ?? this.status,
      orderIds: orderIds ?? this.orderIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'origin': origin,
        'destination': destination,
        'distance': distance,
        'vehicleId': vehicleId,
        'estimatedTime': estimatedTime,
        'status': status,
        'orderIds': orderIds,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Route.fromJson(Map<String, dynamic> json) => Route(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        origin: json['origin'] as String? ?? '',
        destination: json['destination'] as String? ?? '',
        distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
        vehicleId: json['vehicleId'] as int? ?? 0,
        estimatedTime: (json['estimatedTime'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'active',
        orderIds: (json['orderIds'] as List?)?.cast<int>() ?? [],
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
