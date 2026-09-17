import 'package:dio/dio.dart';

import '../models/route.dart';
import '../state/page_result.dart';
import '../state/route_query.dart';

abstract class RouteRepository {
  Future<List<Route>> findAll({bool includeDeleted = false});
  Future<Route?> findById(int id);
  Future<PageResult<Route>> find(
    RouteQuery query, {
    CancelToken? cancelToken,
  });
  Future<Route> create(Route item);
  Future<Route> update(Route item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<List<Route>> findByVehicleId(int vehicleId);
}
