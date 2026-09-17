/// Клиент.
///
/// Хранится в коллекции `clients` PocketBase.
/// Идентификатор — строка (PocketBase использует 15-символьные
/// строковые ID, а не автоинкрементные числа).
class Client {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String email;
  final String? address;

  /// Soft-delete: в PocketBase поле `deleted` (bool).
  /// Кнопка «Скрыть» ставит true, «Восстановить» — false.
  final bool isDeleted;

  const Client({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.address,
    this.isDeleted = false,
  });

  Client copyWith({
    String? id,
    String? companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    bool? isDeleted,
  }) {
    return Client(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id'] as String? ?? '',
    companyName: json['companyName'] as String? ?? '',
    contactPerson: json['contactPerson'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    address: (json['address'] as String?)?.isEmpty == true
        ? null
        : json['address'] as String?,
    isDeleted: json['deleted'] as bool? ?? false,
  );

  /// Для отправки в PocketBase: `id` не кладём — его генерирует
  /// сервер. `deleted` тоже отправляется явно при soft-delete,
  /// а не в составе общего тела.
  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'address': address ?? '',
  };
}
