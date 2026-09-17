import '../models/driver_license.dart';

abstract class DriverLicenseRepository {
  Future<List<DriverLicense>> findAll({bool includeDeleted = false});
  Future<DriverLicense?> findById(String id);
  Future<DriverLicense?> findByVehicleId(String vehicleId);
  Future<DriverLicense> create(DriverLicense item);
  Future<DriverLicense> update(DriverLicense item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
