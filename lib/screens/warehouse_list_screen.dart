import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../models/warehouse.dart';
import '../models/app_user.dart';
import '../state/auth_notifier.dart';
import '../state/warehouse_list_notifier.dart';
import '../state/warehouse_query.dart';
import '../state/load_status.dart';
import '../repositories/warehouse_repository.dart';
import '../repositories/user_repository.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/debounce.dart';
import '../utils/entity_dependencies.dart';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  final Debouncer _debouncer = Debouncer();
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final repo = context.read<UserRepository>();
      final users = await repo.findAll();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (_) {}
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'dry':
        return 'Сухой';
      case 'cold':
        return 'Холодный';
      case 'hazardous':
        return 'Опасные грузы';
      default:
        return 'Все типы';
    }
  }

  String _userName(String? id) {
    if (id == null || id.isEmpty) return '—';
    try {
      return _users.firstWhere((u) => u.id == id).fullName;
    } catch (_) {
      return 'ID $id';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<WarehouseListNotifier>(context);
    final auth = context.watch<AuthNotifier>();

    return MainScaffold(
      title: 'Склады',
      currentRoute: '/warehouses',
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
              onPressed: () => context.go('/warehouses/create'),
              tooltip: 'Создать склад',
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
                      notifier.query.copyWith(
                        includeDeleted: value,
                        page: 1,
                      ),
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
                labelText: 'Поиск по названию или адресу',
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
                    value: notifier.query.type,
                    decoration: const InputDecoration(
                      labelText: 'Тип склада',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все типы')),
                      DropdownMenuItem(value: 'dry', child: Text('Сухой')),
                      DropdownMenuItem(
                        value: 'cold',
                        child: Text('Холодный'),
                      ),
                      DropdownMenuItem(
                        value: 'hazardous',
                        child: Text('Опасные грузы'),
                      ),
                    ],
                    onChanged: (value) {
                      notifier.applyQuery(
                        notifier.query.copyWith(
                          type: value,
                          clearType: value == null,
                          page: 1,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: notifier.query.managerId,
                    decoration: const InputDecoration(
                      labelText: 'Ответственный',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Все'),
                      ),
                      ..._users.map(
                        (u) => DropdownMenuItem<String>(
                          value: u.id,
                          child: Text(u.fullName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      notifier.applyQuery(
                        notifier.query.copyWith(
                          managerId: value,
                          clearManager: value == null,
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
                  if (notifier.query.type != null)
                    ActionChip(
                      label: Text(
                        'Тип: ${_typeLabel(notifier.query.type)}',
                      ),
                      onPressed: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(
                            clearType: true,
                            page: 1,
                          ),
                        );
                      },
                    ),
                  if (notifier.query.managerId != null)
                    ActionChip(
                      label: Text(
                        'Ответственный: ${_userName(notifier.query.managerId)}',
                      ),
                      onPressed: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(
                            clearManager: true,
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
                      notifier.applyQuery(const WarehouseQuery());
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
                  notifier.applyQuery(
                    notifier.query.copyWith(page: page),
                  );
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

  Widget _buildContent(
    WarehouseListNotifier notifier,
    AuthNotifier auth,
  ) {
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
          return const EmptyView(message: 'Нет складов');
        }
        return ResponsiveList<Warehouse>(
          items: notifier.result.items,
          cardBuilder: (w) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                w.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: Text(
                w.address,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: Text(
                '${w.fillPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: w.isOverloaded
                      ? Colors.red
                      : w.isCritical
                          ? Colors.orange
                          : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => context.go('/warehouses/${w.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<Warehouse>(
            items: items,
            idOf: (w) => w.id,
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
              TableColumnSpec<Warehouse>(
                label: 'Название',
                sortField: 'name',
                build: (w) => Text(w.name),
              ),
              TableColumnSpec<Warehouse>(
                label: 'Адрес',
                sortField: 'address',
                build: (w) => Text(w.address),
              ),
              TableColumnSpec<Warehouse>(
                label: 'Тип',
                sortField: 'type',
                build: (w) => Text(w.type.label),
              ),
              TableColumnSpec<Warehouse>(
                label: 'Заполненность',
                build: (w) => Text(
                  '${w.currentLoad.toStringAsFixed(0)} / '
                  '${w.capacity.toStringAsFixed(0)} м³ '
                  '(${w.fillPercent.toStringAsFixed(0)}%)',
                ),
              ),
              TableColumnSpec<Warehouse>(
                label: 'Статус',
                build: (w) => Text(w.isDeleted ? 'Скрыт' : 'Активен'),
              ),
            ],
            actions: (w) => [
              TextButton(
                onPressed: () => context.go('/warehouses/${w.id}'),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              if (auth.uiCanEditBusiness && !w.isDeleted)
                TextButton(
                  onPressed: () => context.go('/warehouses/${w.id}/edit'),
                  child: const Text('Ред.', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanSoftDelete && !w.isDeleted)
                TextButton(
                  onPressed: () => _softDelete(context, w.id),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && !w.isDeleted)
                TextButton(
                  onPressed: () => _hardDelete(context, w),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && w.isDeleted)
                TextButton(
                  onPressed: () => _restore(context, w.id),
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
        title: const Text('Скрыть склад?'),
        content: const Text('Склад будет скрыт.'),
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
    final r = Provider.of<WarehouseRepository>(context, listen: false);
    await r.softDelete(id);
    if (!context.mounted) return;
    final n = Provider.of<WarehouseListNotifier>(context, listen: false);
    await n.load();
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

    final c = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить склад навсегда?'),
        content: const Text('Это действие нельзя отменить!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (c != true) return;
    if (!context.mounted) return;
    final r = Provider.of<WarehouseRepository>(context, listen: false);
    await r.hardDelete(w.id);
    if (!context.mounted) return;
    final n = Provider.of<WarehouseListNotifier>(context, listen: false);
    await n.load();
  }

  Future<void> _restore(BuildContext context, String id) async {
    final r = Provider.of<WarehouseRepository>(context, listen: false);
    await r.restore(id);
    if (!context.mounted) return;
    final n = Provider.of<WarehouseListNotifier>(context, listen: false);
    await n.load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WarehouseListNotifier n,
  ) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Скрыть ${n.selected.length} складов?'),
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
