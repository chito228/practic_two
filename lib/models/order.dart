class Order {
  final int id;
  final String orderNumber;
  final int clientId;
  final List<int> cargoIds;
  final List<int> routeIds;
  final String cargoDescription;
  final double weight;
  final double volume;
  final DateTime shippingDate;
  final DateTime? deliveryDate;
  final String status;
  final DateTime? deletedAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.clientId,
    required this.cargoIds,
    required this.routeIds,
    required this.cargoDescription,
    required this.weight,
    required this.volume,
    required this.shippingDate,
    this.deliveryDate,
    required this.status,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Order copyWith({
    int? id,
    String? orderNumber,
    int? clientId,
    List<int>? cargoIds,
    List<int>? routeIds,
    String? cargoDescription,
    double? weight,
    double? volume,
    DateTime? shippingDate,
    DateTime? deliveryDate,
    String? status,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      clientId: clientId ?? this.clientId,
      cargoIds: cargoIds ?? this.cargoIds,
      routeIds: routeIds ?? this.routeIds,
      cargoDescription: cargoDescription ?? this.cargoDescription,
      weight: weight ?? this.weight,
      volume: volume ?? this.volume,
      shippingDate: shippingDate ?? this.shippingDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'clientId': clientId,
        'cargoIds': cargoIds,
        'routeIds': routeIds,
        'cargoDescription': cargoDescription,
        'weight': weight,
        'volume': volume,
        'shippingDate': shippingDate.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'status': status,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int? ?? 0,
        orderNumber: json['orderNumber'] as String? ?? '',
        clientId: json['clientId'] as int? ?? 0,
        cargoIds: (json['cargoIds'] as List?)?.cast<int>() ?? [],
        routeIds: (json['routeIds'] as List?)?.cast<int>() ?? [],
        cargoDescription: json['cargoDescription'] as String? ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
        shippingDate: json['shippingDate'] == null
            ? DateTime.now()
            : DateTime.parse(json['shippingDate'] as String),
        deliveryDate: json['deliveryDate'] == null
            ? null
            : DateTime.parse(json['deliveryDate'] as String),
        status: json['status'] as String? ?? 'in_transit',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
