import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../models/warehouse.dart';
import '../models/cargo.dart';
import '../models/route.dart' as model;
import '../repositories/warehouse_repository.dart';
import '../repositories/cargo_repository.dart';
import '../repositories/route_repository.dart';
import '../state/auth_notifier.dart';
import '../state/warehouse_list_notifier.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/entity_dependencies.dart';

class WarehouseDetailScreen extends StatelessWidget {
  final String id;
  const WarehouseDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<WarehouseRepository>(context);
    final auth = context.watch<AuthNotifier>();

    return FutureBuilder<Warehouse?>(
      future: repository.findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Склад')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Склад')),
            body: const Center(child: Text('Склад не найден')),
          );
        }
        final w = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(w.name)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('ID', w.id),
                  _infoRow('Название', w.name),
                  _infoRow('Адрес', w.address),
                  _infoRow('Тип', w.type.label),
                  _infoRow(
                    'Вместимость',
                    '${w.capacity.toStringAsFixed(1)} м³',
                  ),
                  _infoRow(
                    'Загрузка',
                    '${w.currentLoad.toStringAsFixed(1)} м³ '
                    '(${w.fillPercent.toStringAsFixed(0)}%)',
                    color: w.isOverloaded
                        ? Colors.red
                        : w.isCritical
                            ? Colors.orange
                            : Colors.green,
                  ),
                  if (w.isOverloaded)
                    _infoRow(
                      'Внимание',
                      'Склад переполнен!',
                      color: Colors.red,
                    )
                  else if (w.isCritical)
                    _infoRow(
                      'Внимание',
                      'Критическая заполненность',
                      color: Colors.orange,
                    ),

                  const Divider(height: 32),
                  const Text(
                    'Грузы',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _cargoList(context, w.cargoIds),

                  const Divider(height: 32),
                  const Text(
                    'Маршруты',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _routeList(context, w.routeIds),

                  if (w.isDeleted)
                    _infoRow('Статус', 'Скрыт', color: Colors.orange),

                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/warehouses'),
                        child: const Text('Назад'),
                      ),
                      if (auth.uiCanEditBusiness && !w.isDeleted)
                        ElevatedButton(
                          onPressed: () =>
                              context.go('/warehouses/${w.id}/edit'),
                          child: const Text('Редактировать'),
                        ),
                      if (!w.isDeleted) ...[
                        if (auth.uiCanSoftDelete)
                          ElevatedButton(
                            onPressed: () => _softDelete(context, w.id),
                            child: const Text('Скрыть'),
                          ),
                        if (auth.uiCanHardDelete)
                          ElevatedButton(
                            onPressed: () => _hardDelete(context, w),
                            child: const Text('Удалить'),
                          ),
                      ] else ...[
                        if (auth.uiCanHardDelete)
                          ElevatedButton(
                            onPressed: () => _restore(context, w.id),
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

  Widget _cargoList(BuildContext context, List<String> cargoIds) {
    if (cargoIds.isEmpty) {
      return const Text('Нет грузов', style: TextStyle(color: Colors.grey));
    }
    return FutureBuilder<List<Cargo>>(
      future: context.read<CargoRepository>().findAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final cargos = snapshot.data!
            .where((c) => cargoIds.contains(c.id))
            .toList();
        if (cargos.isEmpty) {
          return const Text('Нет грузов', style: TextStyle(color: Colors.grey));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cargos
              .map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text('• ${c.name}'),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _routeList(BuildContext context, List<String> routeIds) {
    if (routeIds.isEmpty) {
      return const Text('Нет маршрутов', style: TextStyle(color: Colors.grey));
    }
    return FutureBuilder<List<model.Route>>(
      future: context.read<RouteRepository>().findAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final routes = snapshot.data!
            .where((r) => routeIds.contains(r.id))
            .toList();
        if (routes.isEmpty) {
          return const Text(
            'Нет маршрутов',
            style: TextStyle(color: Colors.grey),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: routes
              .map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text('• ${r.name}'),
                  ))
              .toList(),
        );
      },
    );
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

  Future<void> _softDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть склад?'),
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
    final repo = Provider.of<WarehouseRepository>(context, listen: false);
    await repo.softDelete(id);
    if (!context.mounted) return;
    final notifier =
        Provider.of<WarehouseListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/warehouses');
  }

  Future<void> _hardDelete(BuildContext context, Warehouse w) async {
    final blockers = await EntityDependencies.forWarehouse(context, w.id);

    if (blockers.isNotEmpty) {
      if (!context.mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: w.name,
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
    final repo = Provider.of<WarehouseRepository>(context, listen: false);
    await repo.hardDelete(w.id);
    if (!context.mounted) return;
    final notifier =
        Provider.of<WarehouseListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/warehouses');
  }

  Future<void> _restore(BuildContext context, String id) async {
    if (!context.mounted) return;
    final repo = Provider.of<WarehouseRepository>(context, listen: false);
    await repo.restore(id);
    if (!context.mounted) return;
    final notifier =
        Provider.of<WarehouseListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/warehouses');
  }
}
