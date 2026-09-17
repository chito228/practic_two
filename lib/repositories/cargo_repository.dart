import 'package:dio/dio.dart';

import '../models/cargo.dart';
import '../state/cargo_query.dart';
import '../state/page_result.dart';

abstract class CargoRepository {
  Future<List<Cargo>> findAll({bool includeDeleted = false});
  Future<Cargo?> findById(String id);
  Future<PageResult<Cargo>> find(
    CargoQuery query, {
    CancelToken? cancelToken,
  });
  Future<Cargo> create(Cargo item);
  Future<Cargo> update(Cargo item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
