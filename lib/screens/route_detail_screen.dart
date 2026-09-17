import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../models/vehicle.dart';
import '../repositories/route_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../state/auth_notifier.dart';
import '../state/route_list_notifier.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/entity_dependencies.dart';

class RouteDetailScreen extends StatefulWidget {
  final String id;
  const RouteDetailScreen({super.key, required this.id});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  Vehicle? _vehicle;

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<RouteRepository>(context);
    final auth = context.watch<AuthNotifier>();

    return FutureBuilder(
      future: repository.findById(widget.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Маршрут')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Маршрут')),
            body: const Center(child: Text('Маршрут не найден')),
          );
        }
        final route = snapshot.data!;
        return FutureBuilder<Vehicle?>(
          future: context.read<VehicleRepository>().findById(route.vehicleId),
          builder: (context, vehicleSnapshot) {
            if (vehicleSnapshot.hasData) {
              _vehicle = vehicleSnapshot.data;
            }
            return Scaffold(
              appBar: AppBar(title: Text(route.name)),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('ID', route.id),
                      _infoRow('Название', route.name),
                      _infoRow('Откуда', route.origin),
                      _infoRow('Куда', route.destination),
                      _infoRow('Расстояние', '${route.distance} км'),
                      _infoRow(
                        'Транспорт',
                        _vehicle != null
                            ? '${_vehicle!.plateNumber} (${_vehicle!.driverName})'
                            : 'ID: ${route.vehicleId}',
                      ),
                      _infoRow('Расчётное время', '${route.estimatedTime} ч'),
                      _infoRow('Статус', _getStatusText(route.status)),
                      if (route.isDeleted)
                        _infoRow('Статус', 'Скрыт', color: Colors.orange),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.go('/routes'),
                            child: const Text('Назад'),
                          ),
                          if (auth.uiCanEditBusiness && !route.isDeleted)
                            ElevatedButton(
                              onPressed: () =>
                                  context.go('/routes/${route.id}/edit'),
                              child: const Text('Редактировать'),
                            ),
                          if (!route.isDeleted) ...[
                            if (auth.uiCanSoftDelete)
                              ElevatedButton(
                                onPressed: () =>
                                    _softDelete(context, route.id),
                                child: const Text('Скрыть'),
                              ),
                            if (auth.uiCanHardDelete)
                              ElevatedButton(
                                onPressed: () =>
                                    _hardDelete(context, route),
                                child: const Text('Удалить'),
                              ),
                          ] else ...[
                            if (auth.uiCanHardDelete)
                              ElevatedButton(
                                onPressed: () => _restore(context, route.id),
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
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Активный';
      case 'completed':
        return 'Завершён';
      case 'cancelled':
        return 'Отменён';
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
            width: 120,
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

  Future<void> _softDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть маршрут?'),
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
    if (!context.mounted) return;
    final repository = Provider.of<RouteRepository>(context, listen: false);
    await repository.softDelete(id);
    if (!context.mounted) return;
    final notifier = Provider.of<RouteListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/routes');
  }

  Future<void> _hardDelete(BuildContext context, dynamic route) async {
    final blockers = await EntityDependencies.forRoute(context, route.id);

    if (blockers.isNotEmpty) {
      if (!context.mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: route.name,
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
    if (!context.mounted) return;
    final repository = Provider.of<RouteRepository>(context, listen: false);
    await repository.hardDelete(route.id);
    if (!context.mounted) return;
    final notifier = Provider.of<RouteListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/routes');
  }

  Future<void> _restore(BuildContext context, String id) async {
    if (!context.mounted) return;
    final repository = Provider.of<RouteRepository>(context, listen: false);
    await repository.restore(id);
    if (!context.mounted) return;
    final notifier = Provider.of<RouteListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/routes');
  }
}
