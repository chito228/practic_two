import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../models/vehicle.dart';
import '../state/auth_notifier.dart';
import '../state/vehicle_list_notifier.dart';
import '../state/vehicle_query.dart';
import '../state/load_status.dart';
import '../repositories/vehicle_repository.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/debounce.dart';
import '../utils/entity_dependencies.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final Debouncer _debouncer = Debouncer();

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  String _statusText(String s) {
    switch (s) {
      case 'active':
        return 'В работе';
      case 'maintenance':
        return 'На обслуживании';
      case 'repair':
        return 'В ремонте';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<VehicleListNotifier>(context);
    final auth = context.watch<AuthNotifier>();

    return MainScaffold(
      title: 'Транспорт',
      currentRoute: '/vehicles',
      actions: [
        if (notifier.hasSelection)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(
                'Выбрано: ${notifier.selected.length}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        if (notifier.hasSelection && auth.uiCanSoftDelete)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить выбранные',
            onPressed: () => _confirmDelete(context, notifier),
          ),
      ],
      floatingActionButton: auth.uiCanEditBusiness
          ? FloatingActionButton(
              onPressed: () => context.go('/vehicles/create'),
              tooltip: 'Создать транспорт',
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Показать удалённые'),
                Switch(
                  value: notifier.query.includeDeleted,
                  onChanged: (value) {
                    notifier.applyQuery(
                      notifier.query.copyWith(includeDeleted: value, page: 1),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Поиск по номеру или водителю',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _debouncer.call(() {
                  notifier.applyQuery(
                    notifier.query.copyWith(search: value, page: 1),
                  );
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: notifier.query.status,
              decoration: const InputDecoration(
                labelText: 'Статус',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Все')),
                DropdownMenuItem(value: 'active', child: Text('В работе')),
                DropdownMenuItem(
                  value: 'maintenance',
                  child: Text('На обслуживании'),
                ),
                DropdownMenuItem(value: 'repair', child: Text('В ремонте')),
              ],
              onChanged: (value) {
                notifier.applyQuery(
                  notifier.query.copyWith(
                    status: value,
                    clearStatus: value == null,
                    page: 1,
                  ),
                );
              },
            ),
          ),
          if (notifier.query.hasFilters)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Wrap(
                spacing: 8,
                children: [
                  if (notifier.query.search.isNotEmpty)
                    ActionChip(
                      label: Text('Поиск: ${notifier.query.search}'),
                      onPressed: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(search: '', page: 1),
                        );
                      },
                    ),
                  if (notifier.query.status != null)
                    ActionChip(
                      label: Text(
                        'Статус: ${_statusText(notifier.query.status!)}',
                      ),
                      onPressed: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(
                            clearStatus: true,
                            page: 1,
                          ),
                        );
                      },
                    ),
                  if (notifier.query.includeDeleted)
                    ActionChip(
                      label: const Text('Показаны удалённые'),
                      onPressed: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(
                            includeDeleted: false,
                            page: 1,
                          ),
                        );
                      },
                    ),
                  ActionChip(
                    label: const Text('Сбросить всё'),
                    onPressed: () {
                      notifier.applyQuery(const VehicleQuery());
                    },
                  ),
                ],
              ),
            ),
          Expanded(child: _buildContent(notifier, auth)),
          if (notifier.status == LoadStatus.success &&
              notifier.result.total > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: PaginationControls(
                currentPage: notifier.query.page,
                totalPages: notifier.result.totalPages,
                totalItems: notifier.result.total,
                pageSize: notifier.query.size,
                onPageChanged: (page) {
                  notifier.applyQuery(notifier.query.copyWith(page: page));
                },
                onSizeChanged: (size) {
                  notifier.applyQuery(
                    notifier.query.copyWith(size: size, page: 1),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(VehicleListNotifier notifier, AuthNotifier auth) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case LoadStatus.error:
        return ErrorView(
          message: notifier.error,
          onRetry: () => notifier.load(),
        );

      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const EmptyView(message: 'Нет транспорта');
        }
        return ResponsiveList<Vehicle>(
          items: notifier.result.items,
          cardBuilder: (v) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                v.plateNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                v.driverName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text('${v.capacity} т'),
              onTap: () => context.go('/vehicles/${v.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<Vehicle>(
            items: items,
            idOf: (v) => v.id,
            selected: notifier.selected,
            onToggleSelect: auth.uiCanSoftDelete
                ? notifier.toggleSelection
                : null,
            sortField: notifier.query.sortField,
            sortAscending: notifier.query.sortAscending,
            onSort: (field) {
              notifier.applyQuery(
                notifier.query.copyWith(
                  sortField: field,
                  sortAscending: field == notifier.query.sortField
                      ? !notifier.query.sortAscending
                      : true,
                  page: 1,
                ),
              );
            },
            columns: [
              TableColumnSpec<Vehicle>(
                label: 'Номер',
                sortField: 'plateNumber',
                build: (v) => Text(v.plateNumber),
              ),
              TableColumnSpec<Vehicle>(
                label: 'Водитель',
                sortField: 'driverName',
                build: (v) => Text(v.driverName),
              ),
              TableColumnSpec<Vehicle>(
                label: 'Тоннаж',
                sortField: 'capacity',
                build: (v) => Text('${v.capacity}'),
              ),
              TableColumnSpec<Vehicle>(
                label: 'Статус',
                build: (v) => Text(_statusText(v.status)),
              ),
            ],
            actions: (v) => [
              TextButton(
                onPressed: () => context.go('/vehicles/${v.id}'),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              if (auth.uiCanEditBusiness && !v.isDeleted)
                TextButton(
                  onPressed: () => context.go('/vehicles/${v.id}/edit'),
                  child: const Text('Ред.', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanSoftDelete && !v.isDeleted)
                TextButton(
                  onPressed: () => _softDelete(context, v.id),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && !v.isDeleted)
                TextButton(
                  onPressed: () => _hardDelete(context, v),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && v.isDeleted)
                TextButton(
                  onPressed: () => _restore(context, v.id),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                  child: const Text(
                    'Восстановить',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        );
    }
  }

  Future<void> _softDelete(BuildContext context, String id) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть транспорт?'),
        content: const Text('Транспорт будет скрыт.'),
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
    if (c != true) return;
    if (!context.mounted) return;
    final r = Provider.of<VehicleRepository>(context, listen: false);
    await r.softDelete(id);
    if (!context.mounted) return;
    final n = Provider.of<VehicleListNotifier>(context, listen: false);
    await n.load();
  }

  Future<void> _hardDelete(BuildContext context, Vehicle vehicle) async {
    final blockers = await EntityDependencies.forVehicle(context, vehicle.id);

    if (blockers.isNotEmpty) {
      if (!context.mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: vehicle.plateNumber,
        blockers: blockers,
      );
      return;
    }

    final c = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: const Text('Это действие нельзя отменить!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (c != true) return;
    if (!context.mounted) return;
    final r = Provider.of<VehicleRepository>(context, listen: false);
    await r.hardDelete(vehicle.id);
    if (!context.mounted) return;
    final n = Provider.of<VehicleListNotifier>(context, listen: false);
    await n.load();
  }

  Future<void> _restore(BuildContext context, String id) async {
    final r = Provider.of<VehicleRepository>(context, listen: false);
    await r.restore(id);
    if (!context.mounted) return;
    final n = Provider.of<VehicleListNotifier>(context, listen: false);
    await n.load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VehicleListNotifier n,
  ) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Скрыть ${n.selected.length} единиц?'),
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
    if (c == true) await n.deleteSelected();
  }
}
