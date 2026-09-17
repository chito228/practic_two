/// Водительское удостоверение.
///
/// Связь один-к-одному с транспортным средством:
/// у одной машины — одно удостоверение, у одного удостоверения — одна машина.
/// Уникальность обеспечивается на уровне репозитория
/// (перед созданием проверяется, что у машины ещё нет удостоверения).
class DriverLicense {
  final String id;
  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String category;
  final String vehicleId;
  final bool isDeleted;

  const DriverLicense({
    required this.id,
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
    required this.category,
    required this.vehicleId,
    this.isDeleted = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  DriverLicense copyWith({
    String? id,
    String? number,
    DateTime? issuedAt,
    DateTime? expiresAt,
    String? category,
    String? vehicleId,
    bool? isDeleted,
  }) {
    return DriverLicense(
      id: id ?? this.id,
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      category: category ?? this.category,
      vehicleId: vehicleId ?? this.vehicleId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory DriverLicense.fromJson(Map<String, dynamic> json) => DriverLicense(
        id: json['id'] as String? ?? '',
        number: json['number'] as String? ?? '',
        issuedAt: _parseDate(json['issuedAt']) ?? DateTime.now(),
        expiresAt: _parseDate(json['expiresAt']) ?? DateTime.now(),
        category: json['category'] as String? ?? 'B',
        vehicleId: json['vehicle'] as String? ?? '',
        isDeleted: json['deleted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'category': category,
        'vehicle': vehicleId,
      };
}

/// PocketBase отдаёт даты в формате `2026-09-01 00:00:00.000Z`.
/// Dart `DateTime.parse` такой формат не принимает — нормализуем.
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is! String) return null;

  final s = value.trim();
  if (s.isEmpty) return null;

  final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');

  try {
    return DateTime.parse(normalized);
  } catch (_) {
    return null;
  }
}
