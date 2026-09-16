import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';
import '../repositories/route_repository.dart';
import '../state/auth_notifier.dart';
import '../state/vehicle_list_notifier.dart';

class VehicleDetailScreen extends StatefulWidget {
  final int id;
  const VehicleDetailScreen({super.key, required this.id});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  /// Future хранится в поле состояния, а не создаётся в build().
  /// Это позволяет пересоздавать его через setState после изменения данных.
  late Future<Vehicle?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Vehicle?> _load() {
    return context.read<VehicleRepository>().findById(widget.id);
  }

  /// Перезапросить данные с сервера и перерисовать экран.
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

                  _infoRow(
                    'Количество маршрутов',
                    vehicle.routeIds.length.toString(),
                  ),

                  const Divider(height: 32),
                  const Text(
                    'Водительское удостоверение',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (vehicle.driverLicense != null) ...[
                    _infoRow('Номер', vehicle.driverLicense!.number),
                    _infoRow(
                      'Дата выдачи',
                      vehicle.driverLicense!.issuedAt
                          .toLocal()
                          .toString()
                          .split(' ')[0],
                    ),
                    _infoRow(
                      'Дата истечения',
                      vehicle.driverLicense!.expiresAt
                          .toLocal()
                          .toString()
                          .split(' ')[0],
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Не указано',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],

                  if (vehicle.isDeleted)
                    _infoRow('Статус', 'Скрыт', color: Colors.orange),

                  const SizedBox(height: 32),

                  // ─── Кнопки действий ───
                  // Скрываем то, что недоступно текущей роли.
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/vehicles'),
                        child: const Text('Назад'),
                      ),

                      // Редактирование — только admin.
                      if (auth.uiHas(Role.admin))
                        ElevatedButton(
                          onPressed: () =>
                              context.go('/vehicles/${vehicle.id}/edit'),
                          child: const Text('Редактировать'),
                        ),

                      // Скрытие / удаление / восстановление — только admin.
                      if (!vehicle.isDeleted) ...[
                        if (auth.uiHas(Role.admin))
                          ElevatedButton(
                            onPressed: () => _softDelete(vehicle.id),
                            child: const Text('Скрыть'),
                          ),
                        if (auth.uiHas(Role.admin))
                          ElevatedButton(
                            onPressed: () => _hardDelete(vehicle.id),
                            child: const Text('Удалить'),
                          ),
                      ] else ...[
                        if (auth.uiHas(Role.admin))
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Смена статуса транспорта (logist+)
  // ─────────────────────────────────────────────────────
  Future<void> _changeStatus(int id, String newStatus) async {
    try {
      final dio = context.read<Dio>();
      await dio.patch('/vehicles/$id/status', data: {'status': newStatus});
    } on ForbiddenException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Статус обновлён')),
    );

    // Перезапрашиваем данные с сервера — экран покажет новый статус.
    _reload();

    // Обновляем и список (на случай, если пользователь вернётся назад).
    final listNotifier =
        Provider.of<VehicleListNotifier>(context, listen: false);
    await listNotifier.load();
  }

  // ─────────────────────────────────────────────────────
  // Soft-delete
  // ─────────────────────────────────────────────────────
  Future<void> _softDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть транспорт?'),
        content: const Text(
          'Транспорт будет скрыт, но не удалён. Его можно будет восстановить.',
        ),
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

    try {
      final repository =
          Provider.of<VehicleRepository>(context, listen: false);
      await repository.softDelete(id);
    } on ForbiddenException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ConflictException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!mounted) return;
    final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
    await notifier.load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Транспорт скрыт')),
    );
    context.go('/vehicles');
  }

  // ─────────────────────────────────────────────────────
  // Hard-delete
  // ─────────────────────────────────────────────────────
  Future<void> _hardDelete(int id) async {
    final routeRepo = Provider.of<RouteRepository>(context, listen: false);

    List<dynamic> routes;
    try {
      routes = await routeRepo.findByVehicleId(id);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return;
    }
    if (!mounted) return;

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
                    child: Text(
                      '• ${route.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
              const SizedBox(height: 12),
              Text(
                'Количество маршрутов: ${routes.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
            child: const Text(
              'Удалить навсегда',
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final repository =
          Provider.of<VehicleRepository>(context, listen: false);
      await repository.hardDelete(id);
    } on ForbiddenException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ConflictException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!mounted) return;
    final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
    await notifier.load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Транспорт удалён навсегда')),
    );
    context.go('/vehicles');
  }

  // ─────────────────────────────────────────────────────
  // Restore
  // ─────────────────────────────────────────────────────
  Future<void> _restore(int id) async {
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
    if (!mounted) return;

    try {
      final repository =
          Provider.of<VehicleRepository>(context, listen: false);
      await repository.restore(id);
    } on ForbiddenException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ConflictException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!mounted) return;
    final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
    await notifier.load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Транспорт восстановлен')),
    );
    context.go('/vehicles');
  }
}
