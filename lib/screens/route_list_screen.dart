import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../models/vehicle.dart';
import '../models/route.dart' as model;
import '../state/auth_notifier.dart';
import '../state/route_list_notifier.dart';
import '../state/route_query.dart';
import '../state/load_status.dart';
import '../repositories/route_repository.dart';
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

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  final Debouncer _debouncer = Debouncer();
  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final repo = context.read<VehicleRepository>();
      final v = await repo.findAll();
      if (!mounted) return;
      setState(() => _vehicles = v);
    } catch (_) {}
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  String _statusText(String? s) {
    switch (s) {
      case 'active':
        return 'Активный';
      case 'completed':
        return 'Завершён';
      case 'cancelled':
        return 'Отменён';
      default:
        return 'Все статусы';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<RouteListNotifier>(context);
    final auth = context.watch<AuthNotifier>();

    return MainScaffold(
      title: 'Маршруты',
      currentRoute: '/routes',
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
              onPressed: () => context.go('/routes/create'),
              tooltip: 'Создать маршрут',
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
                labelText: 'Поиск по названию, откуда, куда',
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
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: notifier.query.status,
                    decoration: const InputDecoration(
                      labelText: 'Статус',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все')),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Активный'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Завершён'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Отменён'),
                      ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: notifier.query.vehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Транспорт',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Все'),
                      ),
                      ..._vehicles.map(
                        (v) => DropdownMenuItem<String>(
                          value: v.id,
                          child: Text(v.plateNumber),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      notifier.applyQuery(
                        notifier.query.copyWith(
                          vehicleId: value,
                          clearVehicle: value == null,
                          page: 1,
                        ),
                      );
                    },
                  ),
                ),
              ],
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
                        'Статус: ${_statusText(notifier.query.status)}',
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
                  if (notifier.query.vehicleId != null)
                    ActionChip(
                      label: Text(
                        'Транспорт: ${notifier.query.vehicleId}',
                      ),
                      onPressed: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(
                            clearVehicle: true,
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
                      notifier.applyQuery(const RouteQuery());
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

  Widget _buildContent(RouteListNotifier notifier, AuthNotifier auth) {
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
          return const EmptyView(message: 'Нет маршрутов');
        }
        return ResponsiveList<model.Route>(
          items: notifier.result.items,
          cardBuilder: (route) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                route.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${route.origin} → ${route.destination}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text('${route.distance} км'),
              onTap: () => context.go('/routes/${route.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<model.Route>(
            items: items,
            idOf: (r) => r.id,
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
              TableColumnSpec<model.Route>(
                label: 'Название',
                sortField: 'name',
                build: (r) => Text(r.name),
              ),
              TableColumnSpec<model.Route>(
                label: 'Откуда',
                build: (r) => Text(r.origin),
              ),
              TableColumnSpec<model.Route>(
                label: 'Куда',
                build: (r) => Text(r.destination),
              ),
              TableColumnSpec<model.Route>(
                label: 'Расстояние',
                sortField: 'distance',
                build: (r) => Text('${r.distance} км'),
              ),
              TableColumnSpec<model.Route>(
                label: 'Статус',
                build: (r) => Text(_statusText(r.status)),
              ),
            ],
            actions: (r) => [
              TextButton(
                onPressed: () => context.go('/routes/${r.id}'),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              if (auth.uiCanEditBusiness && !r.isDeleted)
                TextButton(
                  onPressed: () => context.go('/routes/${r.id}/edit'),
                  child: const Text('Ред.', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanSoftDelete && !r.isDeleted)
                TextButton(
                  onPressed: () => _softDelete(context, r.id),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && !r.isDeleted)
                TextButton(
                  onPressed: () => _hardDelete(context, r),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && r.isDeleted)
                TextButton(
                  onPressed: () => _restore(context, r.id),
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
    final repo = Provider.of<RouteRepository>(context, listen: false);
    await repo.softDelete(id);
    if (!context.mounted) return;
    final notifier = Provider.of<RouteListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _hardDelete(BuildContext context, model.Route route) async {
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
        title: const Text('Удалить маршрут навсегда?'),
        content: const Text('Это действие нельзя отменить!'),
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
    final repo = Provider.of<RouteRepository>(context, listen: false);
    await repo.hardDelete(route.id);
    if (!context.mounted) return;
    final notifier = Provider.of<RouteListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _restore(BuildContext context, String id) async {
    final repo = Provider.of<RouteRepository>(context, listen: false);
    await repo.restore(id);
    if (!context.mounted) return;
    final notifier = Provider.of<RouteListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RouteListNotifier n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Скрыть ${n.selected.length} маршрутов?'),
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
    if (confirmed == true) await n.deleteSelected();
  }
}
