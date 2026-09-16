import '../models/route.dart';
import 'base_repository.dart';
import 'route_repository.dart';

class PersistentRouteRepository extends BaseRepository<Route>
    implements RouteRepository {
  PersistentRouteRepository(super.prefs, super.key);

  @override
  String get key => 'routes_v1';

  @override
  Route fromJson(Map<String, dynamic> json) => Route.fromJson(json);

  @override
  Map<String, dynamic> toJson(Route item) => item.toJson();

  @override
  List<Route> seedData() => [
    Route(
      id: 1,
      name: 'Москва-Санкт-Петербург',
      origin: 'Москва',
      destination: 'Санкт-Петербург',
      distance: 700.0,
      vehicleId: 1,
      estimatedTime: 8.0,
      status: 'active',
      orderIds: [1, 3],
    ),
    Route(
      id: 2,
      name: 'Москва-Казань',
      origin: 'Москва',
      destination: 'Казань',
      distance: 800.0,
      vehicleId: 2,
      estimatedTime: 10.0,
      status: 'active',
      orderIds: [2, 5],
    ),
    Route(
      id: 3,
      name: 'Санкт-Петербург-Казань',
      origin: 'Санкт-Петербург',
      destination: 'Казань',
      distance: 1200.0,
      vehicleId: 1,
      estimatedTime: 15.0,
      status: 'completed',
      orderIds: [4],
    ),
  ];

  @override
  Route createCopyWithNewId(Route item, int newId) {
    return Route(
      id: newId,
      name: item.name,
      origin: item.origin,
      destination: item.destination,
      distance: item.distance,
      vehicleId: item.vehicleId,
      estimatedTime: item.estimatedTime,
      status: 'active',
      orderIds: [],
    );
  }

  @override
  Route softDeleteItem(Route item) {
    return item.copyWith(deletedAt: DateTime.now());
  }

  @override
  Route restoreItem(Route item) {
    return item.copyWith(clearDeletedAt: true);
  }

  @override
  Future<List<Route>> findAll({bool includeDeleted = false}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (includeDeleted) return List.from(items);
    return items.where((r) => !r.isDeleted).toList();
  }

  @override
  Future<List<Route>> findByVehicleId(int vehicleId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return items
        .where((r) => r.vehicleId == vehicleId && !r.isDeleted)
        .toList();
  }
}
