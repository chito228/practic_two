/// Заказ.
class Order {
  final String id;
  final String orderNumber;
  final String clientId;
  final List<String> cargoIds;
  final List<String> routeIds;
  final String cargoDescription;
  final double weight;
  final double volume;
  final DateTime shippingDate;
  final DateTime? deliveryDate;
  final String status;
  final bool isDeleted;

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
    this.isDeleted = false,
  });

  Order copyWith({
    String? id,
    String? orderNumber,
    String? clientId,
    List<String>? cargoIds,
    List<String>? routeIds,
    String? cargoDescription,
    double? weight,
    double? volume,
    DateTime? shippingDate,
    DateTime? deliveryDate,
    String? status,
    bool? isDeleted,
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
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String? ?? '',
    orderNumber: json['orderNumber'] as String? ?? '',
    clientId: json['client'] as String? ?? '',
    cargoIds: (json['cargo'] as List?)?.cast<String>() ?? const [],
    routeIds: (json['routes'] as List?)?.cast<String>() ?? const [],
    cargoDescription: json['cargoDescription'] as String? ?? '',
    weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
    shippingDate: _parseDate(json['shippingDate']) ?? DateTime.now(),
    deliveryDate: _parseDate(json['deliveryDate']),
    status: json['status'] as String? ?? 'in_transit',
    isDeleted: json['deleted'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'orderNumber': orderNumber,
    'client': clientId,
    'cargo': cargoIds,
    'routes': routeIds,
    'cargoDescription': cargoDescription,
    'weight': weight,
    'volume': volume,
    'shippingDate': shippingDate.toIso8601String(),
    'deliveryDate': deliveryDate?.toIso8601String(),
    'status': status,
  };
}

/// PocketBase отдаёт даты в формате `2026-09-01 00:00:00.000Z`
/// — с пробелом между датой и временем вместо `T`. Dart
/// `DateTime.parse` такой формат не принимает, поэтому
/// нормализуем строку перед разбором.
///
/// Дополнительно:
///  - пустую строку считаем `null`;
///  - `DateTime` возвращаем как есть;
///  - невалидный формат → `null`, чтобы парсинг не падал.
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is! String) return null;

  final s = value.trim();
  if (s.isEmpty) return null;

  // Меняем первый пробел на 'T': "2026-09-01 00:00:00.000Z"
  // → "2026-09-01T00:00:00.000Z".
  final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');

  try {
    return DateTime.parse(normalized);
  } catch (_) {
    return null;
  }
}
