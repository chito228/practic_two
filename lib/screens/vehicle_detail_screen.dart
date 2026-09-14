import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../repositories/vehicle_repository.dart';
import '../repositories/route_repository.dart';
import '../state/auth_notifier.dart';
import '../state/vehicle_list_notifier.dart';

class VehicleDetailScreen extends StatelessWidget {
  final int id;
  const VehicleDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<VehicleRepository>(context);
    final auth = context.watch<AuthNotifier>();

    return FutureBuilder(
      future: repository.findById(id),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('ID', vehicle.id.toString()),
                _infoRow('Номер машины', vehicle.plateNumber),
                _infoRow('Водитель', vehicle.driverName),
                _infoRow('Грузоподъёмность', '${vehicle.capacity} тонн'),

                // Смена статуса — для logist и admin.
                if (auth.uiHas(Role.logist))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 120,
                          child: Text(
                            'Статус:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DropdownButton<String>(
                          value: vehicle.status,
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('В работе')),
                            DropdownMenuItem(value: 'maintenance', child: Text('На обслуживании')),
                            DropdownMenuItem(value: 'repair', child: Text('В ремонте')),
                          ],
                          onChanged: (v) {
                            if (v != null && v != vehicle.status) {
                              _changeStatus(context, vehicle.id, v);
                            }
                          },
                        ),
                      ],
                    ),
                  )
                else
                  _infoRow('Статус', _getStatusText(vehicle.status)),

                _infoRow('Количество маршрутов', vehicle.routeIds.length.toString()),

                const Divider(height: 32),
                const Text(
                  'Водительское удостоверение',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (vehicle.driverLicense != null) ...[
                  _infoRow('Номер', vehicle.driverLicense!.number),
                  _infoRow('Дата выдачи',
                    vehicle.driverLicense!.issuedAt.toLocal().toString().split(' ')[0]),
                  _infoRow('Дата истечения',
                    vehicle.driverLicense!.expiresAt.toLocal().toString().split(' ')[0]),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Не указано', style: TextStyle(color: Colors.grey)),
                  ),
                ],

                if (vehicle.isDeleted)
                  _infoRow('Статус', 'Скрыт', color: Colors.orange),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/vehicles'),
                      child: const Text('Назад'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.go('/vehicles/${vehicle.id}/edit'),
                      child: const Text('Редактировать'),
                    ),
                    if (!vehicle.isDeleted) ...[
                      ElevatedButton(
                        onPressed: () => _softDelete(context, vehicle.id),
                        child: const Text('Скрыть'),
                      ),
                      ElevatedButton(
                        onPressed: () => _hardDelete(context, vehicle.id),
                        child: const Text('Удалить'),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () => _restore(context, vehicle.id),
                        child: const Text('Восстановить'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'В работе';
      case 'maintenance': return 'На обслуживании';
      case 'repair': return 'В ремонте';
      default: return status;
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
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Смена статуса транспорта (logist+)
  // ─────────────────────────────────────────────────────
  Future<void> _changeStatus(BuildContext context, int id, String newStatus) async {
    try {
      final dio = context.read<Dio>();
      await dio.patch('/vehicles/$id/status', data: {'status': newStatus});
    } on ForbiddenException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Статус обновлён')),
    );
    // Перезагружаем экран, чтобы обновлённый статус отобразился.
    if (context.mounted) {
      context.go('/vehicles/$id');
    }
  }

  Future<void> _softDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть транспорт?'),
        content: const Text('Транспорт будет скрыт, но не удалён. Его можно будет восстановить.'),
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

    try {
      final repository = Provider.of<VehicleRepository>(context, listen: false);
      await repository.softDelete(id);
    } on ForbiddenException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ConflictException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Транспорт скрыт')),
    );
    context.go('/vehicles');
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final routeRepo = Provider.of<RouteRepository>(context, listen: false);

    List<dynamic> routes;
    try {
      routes = await routeRepo.findByVehicleId(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return;
    }
    if (!context.mounted) return;

    if (routes.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить транспорт',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Этот транспорт используется в маршрутах:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...routes.map((route) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('• ${route.name}', style: const TextStyle(fontSize: 14)),
              )),
              const SizedBox(height: 12),
              Text(
                'Количество маршрутов: ${routes.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Сначала удалите или переназначьте маршруты, затем попробуйте снова.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Удалить транспорт навсегда?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Это действие нельзя отменить!',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 14)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить навсегда', style: TextStyle(fontSize: 14, color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final repository = Provider.of<VehicleRepository>(context, listen: false);
      await repository.hardDelete(id);
    } on ForbiddenException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ConflictException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Транспорт удалён навсегда')),
    );
    context.go('/vehicles');
  }

  Future<void> _restore(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить транспорт?'),
        content: const Text('Транспорт снова появится в списке.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final repository = Provider.of<VehicleRepository>(context, listen: false);
      await repository.restore(id);
    } on ForbiddenException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ConflictException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Транспорт восстановлен')),
    );
    context.go('/vehicles');
  }
}
