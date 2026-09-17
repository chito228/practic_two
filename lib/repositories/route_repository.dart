import 'package:dio/dio.dart';

import '../models/route.dart';
import '../state/route_query.dart';
import '../state/page_result.dart';

abstract class RouteRepository {
  Future<List<Route>> findAll({bool includeDeleted = false});
  Future<Route?> findById(String id);
  Future<PageResult<Route>> find(
    RouteQuery query, {
    CancelToken? cancelToken,
  });
  Future<Route> create(Route item);
  Future<Route> update(Route item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
  Future<List<Route>> findByVehicleId(String vehicleId);
}
