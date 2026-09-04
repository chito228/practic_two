import '../models/order.dart';
import '../state/order_query.dart';
import '../state/page_result.dart';
import 'order_repository.dart';

class InMemoryOrderRepository implements OrderRepository {
  final List<Order> _orders = [
    Order(
      id: 1,
      clientId: 1,
      cargoDescription: 'Строительные материалы',
      weight: 1500.0,
      volume: 12.5,
      sendDate: DateTime(2026, 9, 1),
      status: 'доставлено',
    ),
    Order(
      id: 2,
      clientId: 1,
      cargoDescription: 'Электроника',
      weight: 350.0,
      volume: 3.2,
      sendDate: DateTime(2026, 9, 3),
      status: 'в пути',
    ),
    Order(
      id: 3,
      clientId: 2,
      cargoDescription: 'Мебель',
      weight: 800.0,
      volume: 8.0,
      sendDate: DateTime(2026, 8, 28),
      status: 'доставлено',
      deliveryDate: DateTime(2026, 8, 30),
    ),
    Order(
      id: 4,
      clientId: 3,
      cargoDescription: 'Продукты питания',
      weight: 2000.0,
      volume: 15.0,
      sendDate: DateTime(2026, 9, 1),
      status: 'в пути',
    ),
    Order(
      id: 5,
      clientId: 1,
      cargoDescription: 'Запасные части',
      weight: 120.0,
      volume: 1.5,
      sendDate: DateTime(2026, 8, 25),
      status: 'доставлено',
      deliveryDate: DateTime(2026, 8, 27),
    ),
    Order(
      id: 6,
      clientId: 4,
      cargoDescription: 'Химические реагенты',
      weight: 500.0,
      volume: 4.0,
      sendDate: DateTime(2026, 9, 4),
      status: 'в пути',
    ),
    Order(
      id: 7,
      clientId: 2,
      cargoDescription: 'Офисная техника',
      weight: 200.0,
      volume: 2.5,
      sendDate: DateTime(2026, 8, 30),
      status: 'доставлено',
      deliveryDate: DateTime(2026, 9, 1),
    ),
    Order(
      id: 8,
      clientId: 3,
      cargoDescription: 'Упаковочные материалы',
      weight: 3000.0,
      volume: 25.0,
      sendDate: DateTime(2026, 9, 5),
      status: 'в пути',
    ),
    Order(
      id: 9,
      clientId: 4,
      cargoDescription: 'Автомобильные шины',
      weight: 600.0,
      volume: 6.0,
      sendDate: DateTime(2026, 8, 29),
      status: 'отменено',
    ),
    Order(
      id: 10,
      clientId: 3,
      cargoDescription: 'Текстиль',
      weight: 400.0,
      volume: 5.0,
      sendDate: DateTime(2026, 9, 3),
      status: 'в пути',
    ),
    Order(
      id: 11,
      clientId: 5,
      cargoDescription: 'Металлоконструкции',
      weight: 2500.0,
      volume: 18.0,
      sendDate: DateTime(2026, 8, 31),
      status: 'доставлено',
      deliveryDate: DateTime(2026, 9, 3),
    ),
    Order(
      id: 12,
      clientId: 3,
      cargoDescription: 'Бумага и канцтовары',
      weight: 180.0,
      volume: 2.0,
      sendDate: DateTime(2026, 9, 2),
      status: 'в пути',
    ),
    Order(
      id: 13,
      clientId: 6,
      cargoDescription: 'Строительный инструмент',
      weight: 250.0,
      volume: 3.0,
      sendDate: DateTime(2026, 8, 26),
      status: 'доставлено',
      deliveryDate: DateTime(2026, 8, 28),
    ),
    Order(
      id: 14,
      clientId: 7,
      cargoDescription: 'Косметическая продукция',
      weight: 100.0,
      volume: 1.0,
      sendDate: DateTime(2026, 9, 4),
      status: 'в пути',
    ),
    Order(
      id: 15,
      clientId: 5,
      cargoDescription: 'Древесина',
      weight: 1800.0,
      volume: 14.0,
      sendDate: DateTime(2026, 8, 27),
      status: 'доставлено',
      deliveryDate: DateTime(2026, 8, 29),
    ),
    Order(
      id: 16,
      clientId: 6,
      cargoDescription: 'Лаки и краски',
      weight: 300.0,
      volume: 2.8,
      sendDate: DateTime(2026, 9, 1),
      status: 'отменено',
    ),
    Order(
      id: 17,
      clientId: 7,
      cargoDescription: 'Пластиковые изделия',
      weight: 450.0,
      volume: 4.5,
      sendDate: DateTime(2026, 8, 30),
      status: 'доставлено',
      deliveryDate: DateTime(2026, 9, 2),
    ),
    Order(
      id: 18,
      clientId: 5,
      cargoDescription: 'Электрические кабели',
      weight: 750.0,
      volume: 7.0,
      sendDate: DateTime(2026, 9, 5),
      status: 'в пути',
    ),
    Order(
      id: 19,
      clientId: 7,
      cargoDescription: 'Промышленные фильтры',
      weight: 280.0,
      volume: 3.5,
      sendDate: DateTime(2026, 8, 28),
      status: 'доставлено',
      deliveryDate: DateTime(2026, 8, 31),
    ),
    Order(
      id: 20,
      clientId: 7,
      cargoDescription: 'Сантехническое оборудование',
      weight: 550.0,
      volume: 5.5,
      sendDate: DateTime(2026, 9, 3),
      status: 'в пути',
    ),
  ];

  int _nextId = 21;

  @override
  Future<PageResult<Order>> find(OrderQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    var rows = _orders.where((o) => q.includeDeleted || !o.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((o) =>
        o.cargoDescription.toLowerCase().contains(needle)
      ).toList();
    }

    if (q.status != null) {
      rows = rows.where((o) => o.status == q.status).toList();
    }

    if (q.clientId != null) {
      rows = rows.where((o) => o.clientId == q.clientId).toList();
    }

    if (q.dateFrom != null) {
      rows = rows.where((o) => 
        o.sendDate.isAfter(q.dateFrom!) || o.sendDate.isAtSameMomentAs(q.dateFrom!)
      ).toList();
    }

    if (q.dateTo != null) {
      rows = rows.where((o) => 
        o.sendDate.isBefore(q.dateTo!) || o.sendDate.isAtSameMomentAs(q.dateTo!)
      ).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'cargoDescription' => a.cargoDescription.compareTo(b.cargoDescription),
        'weight' => a.weight.compareTo(b.weight),
        'sendDate' => a.sendDate.compareTo(b.sendDate),
        _ => a.sendDate.compareTo(b.sendDate),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Order>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Order?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Order>> findAll() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _orders.where((o) => !o.isDeleted).toList();
  }

  @override
  Future<List<Order>> findByClientId(int clientId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _orders
        .where((o) => o.clientId == clientId && !o.isDeleted)
        .toList();
  }

  @override
  Future<Order> create(Order order) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final newOrder = Order(
      id: _nextId++,
      clientId: order.clientId,
      cargoDescription: order.cargoDescription,
      weight: order.weight,
      volume: order.volume,
      sendDate: order.sendDate,
      deliveryDate: order.deliveryDate,
      status: order.status,
    );
    _orders.add(newOrder);
    return newOrder;
  }

  @override
  Future<Order> update(Order order) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final i = _orders.indexWhere((o) => o.id == order.id);
    if (i == -1) throw StateError('Заказ ${order.id} не найден');
    _orders[i] = order;
    return order;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final i = _orders.indexWhere((o) => o.id == id);
    if (i == -1) throw StateError('Заказ $id не найден');
    _orders[i] = _orders[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _orders.removeWhere((o) => o.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final i = _orders.indexWhere((o) => o.id == id);
    if (i == -1) throw StateError('Заказ $id не найден');
    _orders[i] = _orders[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future.delayed(const Duration(milliseconds: 50));
    var count = 0;
    for (final id in ids) {
      final i = _orders.indexWhere((o) => o.id == id && !o.isDeleted);
      if (i != -1) {
        _orders[i] = _orders[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
