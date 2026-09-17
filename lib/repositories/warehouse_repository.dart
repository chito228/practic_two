import 'package:dio/dio.dart';

import '../models/warehouse.dart';
import '../state/page_result.dart';
import '../state/warehouse_query.dart';

abstract class WarehouseRepository {
  Future<List<Warehouse>> findAll({bool includeDeleted = false});
  Future<Warehouse?> findById(int id);
  Future<PageResult<Warehouse>> find(
    WarehouseQuery query, {
    CancelToken? cancelToken,
  });
  Future<Warehouse> create(Warehouse item);
  Future<Warehouse> update(Warehouse item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
