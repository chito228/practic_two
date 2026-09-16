import '../models/cargo.dart';

/// Интерфейс репозитория грузов.
abstract class CargoRepository {
  Future<List<Cargo>> findAll({bool includeDeleted = false});
  Future<Cargo?> findById(int id);
  Future<Cargo> create(Cargo item);
  Future<Cargo> update(Cargo item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
