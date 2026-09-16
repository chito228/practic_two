class Client {
  final int id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String email;
  final String? address;
  final List<int> orderIds;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.address,
    required this.orderIds,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Client copyWith({
    int? id,
    String? companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    List<int>? orderIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      orderIds: orderIds ?? this.orderIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'orderIds': orderIds,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Client.fromJson(Map<String, dynamic> json) {
    String? address;
    final addressValue = json['address'];
    if (addressValue != null &&
        addressValue is String &&
        addressValue.isNotEmpty) {
      address = addressValue;
    }

    List<int> orderIds = [];
    final orderIdsValue = json['orderIds'];
    if (orderIdsValue is List) {
      orderIds = orderIdsValue.cast<int>();
    }

    return Client(
      id: json['id'] as int? ?? 0,
      companyName: json['companyName'] as String? ?? '',
      contactPerson: json['contactPerson'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: address,
      orderIds: orderIds,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );
  }
}
