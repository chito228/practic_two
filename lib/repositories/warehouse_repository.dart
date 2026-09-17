import 'package:dio/dio.dart';

import '../models/warehouse.dart';
import '../state/warehouse_query.dart';
import '../state/page_result.dart';

abstract class WarehouseRepository {
  Future<List<Warehouse>> findAll({bool includeDeleted = false});
  Future<Warehouse?> findById(String id);
  Future<PageResult<Warehouse>> find(
    WarehouseQuery query, {
    CancelToken? cancelToken,
  });
  Future<Warehouse> create(Warehouse item);
  Future<Warehouse> update(Warehouse item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
