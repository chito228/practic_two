import '../models/vehicle.dart';
import 'base_repository.dart';
import 'vehicle_repository.dart';

class PersistentVehicleRepository extends BaseRepository<Vehicle>
    implements VehicleRepository {
  PersistentVehicleRepository(super.prefs, super.key);

  @override
  String get key => 'vehicles_v1';

  @override
  Vehicle fromJson(Map<String, dynamic> json) => Vehicle.fromJson(json);

  @override
  Map<String, dynamic> toJson(Vehicle item) => item.toJson();

  @override
  List<Vehicle> seedData() => [
    Vehicle(
      id: 1,
      plateNumber: 'А123ВС 777',
      driverName: 'Иванов Иван Иванович',
      capacity: 2000.0,
      status: 'active',
      driverLicense: DriverLicense(
        id: 1,
        number: 'DL-001',
        issuedAt: DateTime(2020, 1, 15),
        expiresAt: DateTime(2025, 1, 15),
        vehicleId: 1,
      ),
      routeIds: [1, 3],
    ),
    Vehicle(
      id: 2,
      plateNumber: 'В456УЕ 777',
      driverName: 'Петров Петр Петрович',
      capacity: 1500.0,
      status: 'active',
      driverLicense: DriverLicense(
        id: 2,
        number: 'DL-002',
        issuedAt: DateTime(2021, 3, 10),
        expiresAt: DateTime(2026, 3, 10),
        vehicleId: 2,
      ),
      routeIds: [2],
    ),
    Vehicle(
      id: 3,
      plateNumber: 'С789ОК 777',
      driverName: 'Сидоров Сидор Сидорович',
      capacity: 3000.0,
      status: 'maintenance',
      driverLicense: DriverLicense(
        id: 3,
        number: 'DL-003',
        issuedAt: DateTime(2019, 6, 20),
        expiresAt: DateTime(2024, 6, 20),
        vehicleId: 3,
      ),
      routeIds: [],
    ),
  ];

  @override
  Vehicle createCopyWithNewId(Vehicle item, int newId) {
    return Vehicle(
      id: newId,
      plateNumber: item.plateNumber,
      driverName: item.driverName,
      capacity: item.capacity,
      status: 'active',
      driverLicense: null,
      routeIds: [],
    );
  }

  @override
  Vehicle softDeleteItem(Vehicle item) {
    return item.copyWith(deletedAt: DateTime.now());
  }

  @override
  Vehicle restoreItem(Vehicle item) {
    return item.copyWith(clearDeletedAt: true);
  }

  @override
  Future<List<Vehicle>> findAll({bool includeDeleted = false}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (includeDeleted) return List.from(items);
    return items.where((v) => !v.isDeleted).toList();
  }
}
