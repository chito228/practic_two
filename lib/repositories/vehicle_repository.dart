import 'package:dio/dio.dart';

import '../models/vehicle.dart';
import '../state/vehicle_query.dart';
import '../state/page_result.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> findAll({bool includeDeleted = false});
  Future<Vehicle?> findById(String id);
  Future<PageResult<Vehicle>> find(
    VehicleQuery query, {
    CancelToken? cancelToken,
  });
  Future<Vehicle> create(Vehicle item);
  Future<Vehicle> update(Vehicle item);
  Future<Vehicle> updateStatus(String id, String status);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
