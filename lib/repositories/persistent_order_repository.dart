import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import 'base_repository.dart';
import '../state/order_query.dart';
import '../state/page_result.dart';

class PersistentOrderRepository extends BaseRepository<Order> {
  PersistentOrderRepository(super.prefs, super.key);

  @override
  String get key => 'orders_v1';

  @override
  Order fromJson(Map<String, dynamic> json) => Order.fromJson(json);

  @override
  Map<String, dynamic> toJson(Order item) => item.toJson();

  @override
  List<Order> seedData() => [
        Order(
          id: 1,
          orderNumber: 'ORD-001',
          clientId: 1,
          cargoIds: [1],
          routeIds: [1],
          cargoDescription: 'Строительные материалы',
          weight: 1500.0,
          volume: 12.5,
          shippingDate: DateTime(2026, 9, 1),
          status: 'delivered',
          deliveryDate: DateTime(2026, 9, 5),
        ),
        Order(
          id: 2,
          orderNumber: 'ORD-002',
          clientId: 1,
          cargoIds: [2],
          routeIds: [2],
          cargoDescription: 'Электроника',
          weight: 350.0,
          volume: 3.2,
          shippingDate: DateTime(2026, 9, 3),
          status: 'in_transit',
        ),
        Order(
          id: 3,
          orderNumber: 'ORD-003',
          clientId: 2,
          cargoIds: [3],
          routeIds: [1],
          cargoDescription: 'Мебель',
          weight: 800.0,
          volume: 8.0,
          shippingDate: DateTime(2026, 8, 28),
          status: 'delivered',
          deliveryDate: DateTime(2026, 8, 30),
        ),
        Order(
          id: 4,
          orderNumber: 'ORD-004',
          clientId: 3,
          cargoIds: [1, 2],
          routeIds: [3],
          cargoDescription: 'Продукты питания',
          weight: 2000.0,
          volume: 15.0,
          shippingDate: DateTime(2026, 9, 1),
          status: 'in_transit',
        ),
        Order(
          id: 5,
          orderNumber: 'ORD-005',
          clientId: 3,
          cargoIds: [3],
          routeIds: [2],
          cargoDescription: 'Запасные части',
          weight: 120.0,
          volume: 1.5,
          shippingDate: DateTime(2026, 8, 25),
          status: 'cancelled',
        ),
      ];

  @override
  Order createCopyWithNewId(Order item, int newId) {
    return Order(
      id: newId,
      orderNumber: item.orderNumber,
      clientId: item.clientId,
      cargoIds: [],
      routeIds: [],
      cargoDescription: item.cargoDescription,
      weight: item.weight,
      volume: item.volume,
      shippingDate: DateTime.now(),
      status: 'in_transit',
    );
  }

  @override
  Order _softDeleteItem(Order item) {
    return item.copyWith(deletedAt: DateTime.now());
  }

  @override
  Order _restoreItem(Order item) {
    return item.copyWith(clearDeletedAt: true);
  }

  // ============================================================
  // ДОБАВЛЕННЫЙ МЕТОД findByClientId
  // ============================================================
  Future<List<Order>> findByClientId(int clientId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return items
        .where((o) => o.clientId == clientId && !o.isDeleted)
        .toList();
  }

  Future<PageResult<Order>> find(OrderQuery query) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = items
        .where((o) => query.includeDeleted || !o.isDeleted)
        .toList();

    if (query.search.trim().isNotEmpty) {
      final needle = query.search.trim().toLowerCase();
      rows = rows.where((o) =>
          o.orderNumber.toLowerCase().contains(needle) ||
          o.cargoDescription.toLowerCase().contains(needle)).toList();
    }

    if (query.status != null) {
      rows = rows.where((o) => o.status == query.status).toList();
    }

    if (query.clientId != null) {
      rows = rows.where((o) => o.clientId == query.clientId).toList();
    }

    if (query.cargoId != null) {
      rows = rows.where((o) => o.cargoIds.contains(query.cargoId)).toList();
    }

    if (query.routeId != null) {
      rows = rows.where((o) => o.routeIds.contains(query.routeId)).toList();
    }

    if (query.dateFrom != null) {
      rows = rows.where((o) =>
          o.shippingDate.isAfter(query.dateFrom!) ||
          o.shippingDate.isAtSameMomentAs(query.dateFrom!)).toList();
    }

    if (query.dateTo != null) {
      rows = rows.where((o) =>
          o.shippingDate.isBefore(query.dateTo!) ||
          o.shippingDate.isAtSameMomentAs(query.dateTo!)).toList();
    }

    rows.sort((a, b) {
      int result;
      switch (query.sortField) {
        case 'orderNumber':
          result = a.orderNumber.compareTo(b.orderNumber);
          break;
        case 'cargoDescription':
          result = a.cargoDescription.compareTo(b.cargoDescription);
          break;
        case 'weight':
          result = a.weight.compareTo(b.weight);
          break;
        case 'shippingDate':
          result = a.shippingDate.compareTo(b.shippingDate);
          break;
        default:
          result = a.orderNumber.compareTo(b.orderNumber);
      }
      return query.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (query.page - 1) * query.size;
    final to = (from + query.size) > total ? total : (from + query.size);
    final pageItems = from >= total ? <Order>[] : rows.sublist(from, to);

    return PageResult(
      items: pageItems,
      page: query.page,
      size: query.size,
      total: total,
    );
  }
}
