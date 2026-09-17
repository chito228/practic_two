/// Груз.
class Cargo {
  final String id;
  final String name;
  final String? description;
  final double weightPerUnit;
  final double volumePerUnit;
  final bool isDeleted;

  const Cargo({
    required this.id,
    required this.name,
    this.description,
    required this.weightPerUnit,
    required this.volumePerUnit,
    this.isDeleted = false,
  });

  Cargo copyWith({
    String? id,
    String? name,
    String? description,
    double? weightPerUnit,
    double? volumePerUnit,
    bool? isDeleted,
  }) {
    return Cargo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      weightPerUnit: weightPerUnit ?? this.weightPerUnit,
      volumePerUnit: volumePerUnit ?? this.volumePerUnit,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory Cargo.fromJson(Map<String, dynamic> json) => Cargo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: (json['description'] as String?)?.isEmpty == true
        ? null
        : json['description'] as String?,
    weightPerUnit: (json['weightPerUnit'] as num?)?.toDouble() ?? 0.0,
    volumePerUnit: (json['volumePerUnit'] as num?)?.toDouble() ?? 0.0,
    isDeleted: json['deleted'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description ?? '',
    'weightPerUnit': weightPerUnit,
    'volumePerUnit': volumePerUnit,
  };
}
