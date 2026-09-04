class Order {
  final int id;
  final int clientId;
  final String cargoDescription;
  final double weight;
  final double volume;
  final DateTime sendDate;
  final DateTime? deliveryDate;
  final String status;
  final DateTime? deletedAt;

  const Order({
    required this.id,
    required this.clientId,
    required this.cargoDescription,
    required this.weight,
    required this.volume,
    required this.sendDate,
    this.deliveryDate,
    required this.status,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Order copyWith({
    int? clientId,
    String? cargoDescription,
    double? weight,
    double? volume,
    DateTime? sendDate,
    DateTime? deliveryDate,
    String? status,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Order(
      id: id,
      clientId: clientId ?? this.clientId,
      cargoDescription: cargoDescription ?? this.cargoDescription,
      weight: weight ?? this.weight,
      volume: volume ?? this.volume,
      sendDate: sendDate ?? this.sendDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
