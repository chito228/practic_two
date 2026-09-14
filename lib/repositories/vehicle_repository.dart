import '../models/vehicle.dart';

/// Интерфейс репозитория транспорта.
abstract class VehicleRepository {
  Future<List<Vehicle>> findAll({bool includeDeleted = false});
  Future<Vehicle?> findById(int id);
  Future<Vehicle> create(Vehicle item);
  Future<Vehicle> update(Vehicle item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
