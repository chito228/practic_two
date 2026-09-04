import '../models/order.dart';
import '../state/order_query.dart';
import '../state/page_result.dart';

abstract interface class OrderRepository {
  Future<PageResult<Order>> find(OrderQuery query);
  Future<Order?> findById(int id);
  Future<List<Order>> findAll();
  Future<List<Order>> findByClientId(int clientId);
  Future<Order> create(Order order);
  Future<Order> update(Order order);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
