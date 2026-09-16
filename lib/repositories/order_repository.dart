import 'package:dio/dio.dart';
import '../models/order.dart';
import '../models/client.dart';
import '../models/cargo.dart';
import '../models/route.dart' as model;
import '../state/order_query.dart';
import '../state/page_result.dart';

/// Развёрнутый заказ: с клиентом, грузами и маршрутами.
class OrderFull {
  final Order order;
  final Client? client;
  final List<Cargo> cargo;
  final List<model.Route> routes;

  const OrderFull({
    required this.order,
    required this.client,
    required this.cargo,
    required this.routes,
  });
}

/// Интерфейс репозитория заказов.
abstract class OrderRepository {
  Future<List<Order>> findAll({bool includeDeleted = false});
  Future<Order?> findById(int id);
  Future<OrderFull?> findByIdWithRelations(int id);
  Future<PageResult<Order>> find(
    OrderQuery query, {
    CancelToken? cancelToken,
  });
  Future<Order> create(Order item);
  Future<Order> update(Order item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<List<Order>> findByClientId(int clientId);
}
