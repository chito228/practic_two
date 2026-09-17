import 'package:dio/dio.dart';

import '../models/order.dart';
import '../models/client.dart';
import '../models/cargo.dart';
import '../models/route.dart' as model;
import '../state/order_query.dart';
import '../state/page_result.dart';

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

abstract class OrderRepository {
  Future<List<Order>> findAll({bool includeDeleted = false});
  Future<Order?> findById(String id);
  Future<OrderFull?> findByIdWithRelations(String id);
  Future<PageResult<Order>> find(OrderQuery query, {CancelToken? cancelToken});
  Future<Order> create(Order item);
  Future<Order> update(Order item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
  Future<List<Order>> findByClientId(String clientId);
}
