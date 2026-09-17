/// Маршрут.
class Route {
  final String id;
  final String name;
  final String origin;
  final String destination;
  final double distance;
  final String vehicleId;      // ID записи в коллекции vehicles
  final double estimatedTime;
  final String status;
  final bool isDeleted;

  const Route({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.distance,
    required this.vehicleId,
    required this.estimatedTime,
    required this.status,
    this.isDeleted = false,
  });

  Route copyWith({
    String? id,
    String? name,
    String? origin,
    String? destination,
    double? distance,
    String? vehicleId,
    double? estimatedTime,
    String? status,
    bool? isDeleted,
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
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory Route.fromJson(Map<String, dynamic> json) => Route(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    origin: json['origin'] as String? ?? '',
    destination: json['destination'] as String? ?? '',
    distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    // PocketBase relation приходит как строка ID.
    vehicleId: json['vehicle'] as String? ?? '',
    estimatedTime: (json['estimatedTime'] as num?)?.toDouble() ?? 0.0,
    status: json['status'] as String? ?? 'active',
    isDeleted: json['deleted'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'origin': origin,
    'destination': destination,
    'distance': distance,
    'vehicle': vehicleId,
    'estimatedTime': estimatedTime,
    'status': status,
  };
}
