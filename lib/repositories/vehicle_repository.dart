import 'package:dio/dio.dart';

import '../models/vehicle.dart';
import '../state/page_result.dart';
import '../state/vehicle_query.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> findAll({bool includeDeleted = false});
  Future<Vehicle?> findById(int id);
  Future<PageResult<Vehicle>> find(
    VehicleQuery query, {
    CancelToken? cancelToken,
  });
  Future<Vehicle> create(Vehicle item);
  Future<Vehicle> update(Vehicle item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
