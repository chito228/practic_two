import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/cargo.dart';
import '../models/route.dart' as model;
import '../models/vehicle.dart';
import '../models/order.dart';
import '../models/warehouse.dart';
import '../models/task.dart';
import '../repositories/order_repository.dart';
import '../repositories/route_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/warehouse_repository.dart';
import '../repositories/user_repository.dart';

/// Возвращает список человекочитаемых «блокеров» —
/// сущностей, которые ссылаются на удаляемую запись.
///
/// Пустой список = удалять можно.
class EntityDependencies {
  /// Клиент: кто ссылается — заказы.
  static Future<List<String>> forClient(
    BuildContext context,
    String clientId,
  ) async {
    final orders = await context.read<OrderRepository>().findByClientId(clientId);
    return _line(orders.length, 'заказ', 'заказа', 'заказов');
  }

  /// Груз: заказы + склады.
  static Future<List<String>> forCargo(
    BuildContext context,
    String cargoId,
  ) async {
    final blockers = <String>[];
    try {
      final orders = await context.read<OrderRepository>().findAll();
      final n = orders.where((o) => o.cargoIds.contains(cargoId)).length;
      blockers.addAll(_line(n, 'заказ', 'заказа', 'заказов'));
    } catch (_) {}
    try {
      final warehouses = await context.read<WarehouseRepository>().findAll();
      final n = warehouses.where((w) => w.cargoIds.contains(cargoId)).length;
      blockers.addAll(_line(n, 'склад', 'склада', 'складов'));
    } catch (_) {}
    return blockers;
  }

  /// Маршрут: заказы + задачи + склады.
  static Future<List<String>> forRoute(
    BuildContext context,
    String routeId,
  ) async {
    final blockers = <String>[];
    try {
      final orders = await context.read<OrderRepository>().findAll();
      final n = orders.where((o) => o.routeIds.contains(routeId)).length;
      blockers.addAll(_line(n, 'заказ', 'заказа', 'заказов'));
    } catch (_) {}
    try {
      final tasks = await context.read<TaskRepository>().findAll();
      final n = tasks.where((t) => t.routeId == routeId).length;
      blockers.addAll(_line(n, 'задача', 'задачи', 'задач'));
    } catch (_) {}
    try {
      final warehouses = await context.read<WarehouseRepository>().findAll();
      final n = warehouses.where((w) => w.routeIds.contains(routeId)).length;
      blockers.addAll(_line(n, 'склад', 'склада', 'складов'));
    } catch (_) {}
    return blockers;
  }

  /// Транспорт: маршруты.
  static Future<List<String>> forVehicle(
    BuildContext context,
    String vehicleId,
  ) async {
    final routes =
        await context.read<RouteRepository>().findByVehicleId(vehicleId);
    return _line(routes.length, 'маршрут', 'маршрута', 'маршрутов');
  }

  /// Пользователь: задачи (assignedTo, createdBy) + склады (manager).
  static Future<List<String>> forUser(
    BuildContext context,
    String userId,
  ) async {
    final blockers = <String>[];
    try {
      final tasks = await context.read<TaskRepository>().findAll();
      final assigned = tasks.where((t) => t.assignedToId == userId).length;
      blockers.addAll(_line(assigned, 'задача (исполнитель)',
          'задачи (исполнитель)', 'задач (исполнитель)'));
      final created = tasks.where((t) => t.createdById == userId).length;
      blockers.addAll(_line(created, 'задача (автор)',
          'задачи (автор)', 'задач (автор)'));
    } catch (_) {}
    try {
      final warehouses = await context.read<WarehouseRepository>().findAll();
      final n = warehouses.where((w) => w.managerId == userId).length;
      blockers.addAll(_line(n, 'склад', 'склада', 'складов'));
    } catch (_) {}
    return blockers;
  }

  /// Заказ: задачи.
  static Future<List<String>> forOrder(
    BuildContext context,
    String orderId,
  ) async {
    final tasks = await context.read<TaskRepository>().findAll();
    final n = tasks.where((t) => t.orderId == orderId).length;
    return _line(n, 'задача', 'задачи', 'задач');
  }

  /// Склад: никто не ссылается — всегда пусто.
  static Future<List<String>> forWarehouse(
    BuildContext context,
    String warehouseId,
  ) async {
    return const [];
  }

  /// Задача: никто не ссылается — всегда пусто.
  static Future<List<String>> forTask(
    BuildContext context,
    String taskId,
  ) async {
    return const [];
  }

  /// Формирует строку вида «2 заказа». Возвращает пустой список,
  /// если n == 0 — чтобы не плодить «0 заказов».
  static List<String> _line(int n, String one, String few, String many) {
    if (n <= 0) return const [];
    return ['$n ${_plural(n, one, few, many)}'];
  }

  static String _plural(int n, String one, String few, String many) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return few;
    return many;
  }
}
