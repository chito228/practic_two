class Cargo {
  final int id;
  final String name;
  final String? description;
  final double weightPerUnit;
  final double volumePerUnit;
  final List<int> orderIds;
  final DateTime? deletedAt;

  const Cargo({
    required this.id,
    required this.name,
    this.description,
    required this.weightPerUnit,
    required this.volumePerUnit,
    required this.orderIds,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Cargo copyWith({
    int? id,
    String? name,
    String? description,
    double? weightPerUnit,
    double? volumePerUnit,
    List<int>? orderIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Cargo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      weightPerUnit: weightPerUnit ?? this.weightPerUnit,
      volumePerUnit: volumePerUnit ?? this.volumePerUnit,
      orderIds: orderIds ?? this.orderIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'weightPerUnit': weightPerUnit,
        'volumePerUnit': volumePerUnit,
        'orderIds': orderIds,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Cargo.fromJson(Map<String, dynamic> json) => Cargo(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        weightPerUnit: (json['weightPerUnit'] as num?)?.toDouble() ?? 0.0,
        volumePerUnit: (json['volumePerUnit'] as num?)?.toDouble() ?? 0.0,
        orderIds: (json['orderIds'] as List?)?.cast<int>() ?? [],
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
