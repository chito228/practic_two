import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../models/vehicle.dart';
import '../models/driver_license.dart';
import '../repositories/vehicle_repository.dart';
import '../repositories/driver_license_repository.dart';
import '../state/auth_notifier.dart';
import '../state/vehicle_list_notifier.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/entity_dependencies.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String id;
  const VehicleDetailScreen({super.key, required this.id});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Future<Vehicle?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Vehicle?> _load() {
    return context.read<VehicleRepository>().findById(widget.id);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return FutureBuilder<Vehicle?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Транспорт')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Транспорт')),
            body: const Center(child: Text('Транспорт не найден')),
          );
        }
        final vehicle = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(vehicle.plateNumber)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('ID', vehicle.id),
                  _infoRow('Номер машины', vehicle.plateNumber),
                  _infoRow('Водитель', vehicle.driverName),
                  _infoRow('Грузоподъёмность', '${vehicle.capacity} тонн'),

                  // ─── Водительское удостоверение (1:1) ───
                  FutureBuilder<DriverLicense?>(
                    future: context
                        .read<DriverLicenseRepository>()
                        .findByVehicleId(vehicle.id),
                    builder: (context, licSnap) {
                      if (licSnap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(),
                        );
                      }
                      final lic = licSnap.data;
                      if (lic == null) {
                        return _infoRow('Удостоверение', 'нет');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Удостоверение №', lic.number),
                          _infoRow('Категория', lic.category),
                          _infoRow(
                            'Выдано',
                            lic.issuedAt.toLocal().toString().split(' ')[0],
                          ),
                          _infoRow(
                            'Действительно до',
                            lic.expiresAt.toLocal().toString().split(' ')[0],
                            color: lic.isExpired ? Colors.red : Colors.black,
                          ),
                        ],
                      );
                    },
                  ),

                  if (auth.uiCanEditBusiness)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Статус:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          DropdownButton<String>(
                            value: vehicle.status,
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('В работе'),
                              ),
                              DropdownMenuItem(
                                value: 'maintenance',
                                child: Text('На обслуживании'),
                              ),
                              DropdownMenuItem(
                                value: 'repair',
                                child: Text('В ремонте'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null && v != vehicle.status) {
                                _changeStatus(vehicle.id, v);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    _infoRow('Статус', _getStatusText(vehicle.status)),

                  if (vehicle.isDeleted)
                    _infoRow('Статус', 'Скрыт', color: Colors.orange),

                  const SizedBox(height: 32),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/vehicles'),
                        child: const Text('Назад'),
                      ),
                      if (auth.uiCanEditBusiness && !vehicle.isDeleted)
                        ElevatedButton(
                          onPressed: () =>
                              context.go('/vehicles/${vehicle.id}/edit'),
                          child: const Text('Редактировать'),
                        ),
                      if (!vehicle.isDeleted) ...[
                        if (auth.uiCanSoftDelete)
                          ElevatedButton(
                            onPressed: () => _softDelete(vehicle.id),
                            child: const Text('Скрыть'),
                          ),
                        if (auth.uiCanHardDelete)
                          ElevatedButton(
                            onPressed: () => _hardDelete(vehicle),
                            child: const Text('Удалить'),
                          ),
                      ] else ...[
                        if (auth.uiCanHardDelete)
                          ElevatedButton(
                            onPressed: () => _restore(vehicle.id),
                            child: const Text('Восстановить'),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'В работе';
      case 'maintenance':
        return 'На обслуживании';
      case 'repair':
        return 'В ремонте';
      default:
        return status;
    }
  }

  Widget _infoRow(String label, String value, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(String id, String newStatus) async {
    try {
      final repo = context.read<VehicleRepository>();
      await repo.updateStatus(id, newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Статус обновлён')));
    _reload();
    final listNotifier = Provider.of<VehicleListNotifier>(
      context,
      listen: false,
    );
    await listNotifier.load();
  }

  Future<void> _softDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть транспорт?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Скрыть'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final repository = Provider.of<VehicleRepository>(context, listen: false);
    await repository.softDelete(id);
    if (!mounted) return;
    final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
    await notifier.load();
    if (!mounted) return;
    context.go('/vehicles');
  }

  Future<void> _hardDelete(Vehicle vehicle) async {
    final blockers = await EntityDependencies.forVehicle(context, vehicle.id);

    if (blockers.isNotEmpty) {
      if (!mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: vehicle.plateNumber,
        blockers: blockers,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final repository = Provider.of<VehicleRepository>(context, listen: false);
    await repository.hardDelete(vehicle.id);
    if (!mounted) return;
    final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
    await notifier.load();
    if (!mounted) return;
    context.go('/vehicles');
  }

  Future<void> _restore(String id) async {
    if (!mounted) return;
    final repository = Provider.of<VehicleRepository>(context, listen: false);
    await repository.restore(id);
    if (!mounted) return;
    final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
    await notifier.load();
    if (!mounted) return;
    context.go('/vehicles');
  }
}
