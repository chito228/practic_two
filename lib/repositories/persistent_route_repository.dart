import 'package:shared_preferences/shared_preferences.dart';
import '../models/route.dart';
import 'base_repository.dart';

class PersistentRouteRepository extends BaseRepository<Route> {
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
  Route _softDeleteItem(Route item) {
    return item.copyWith(deletedAt: DateTime.now());
  }

  @override
  Route _restoreItem(Route item) {
    return item.copyWith(clearDeletedAt: true);
  }
}
