import '../models/route.dart';

/// Интерфейс репозитория маршрутов.
abstract class RouteRepository {
  Future<List<Route>> findAll({bool includeDeleted = false});
  Future<Route?> findById(int id);
  Future<Route> create(Route item);
  Future<Route> update(Route item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<List<Route>> findByVehicleId(int vehicleId);
}
