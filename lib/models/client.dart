class Client {
  final int id;
  final String name;
  final String contactPerson;
  final String phone;
  final List<int> orderIds;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.orderIds,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Client copyWith({
    String? name,
    String? contactPerson,
    String? phone,
    List<int>? orderIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      orderIds: orderIds ?? this.orderIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
