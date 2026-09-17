import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../models/warehouse.dart';
import '../models/app_user.dart';
import '../state/auth_notifier.dart';
import '../state/warehouse_list_notifier.dart';
import '../state/warehouse_query.dart';
import '../repositories/warehouse_repository.dart';
import '../repositories/user_repository.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/pagination_controls.dart';
import '../utils/debounce.dart';
import '../state/load_status.dart';

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
    } catch (_) {
      // Игнорируем — фильтр по менеджеру опциональный.
    }
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

  String _userName(int? id) {
    if (id == null) return '—';
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
        if (notifier.hasSelection && auth.uiHasExactly(Role.logist))
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить выбранные',
            onPressed: () => _confirmDelete(context, notifier),
          ),
      ],
      floatingActionButton: auth.uiHasExactly(Role.logist)
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
                  child: DropdownButtonFormField<int>(
                    value: notifier.query.managerId,
                    decoration: const InputDecoration(
                      labelText: 'Ответственный',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Все'),
                      ),
                      ..._users.map(
                        (u) => DropdownMenuItem<int>(
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              onTap: () => context.go('/warehouses/${w.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<Warehouse>(
            items: items,
            idOf: (w) => w.id,
            selected: notifier.selected,
            onToggleSelect: auth.uiHasExactly(Role.logist)
                ? notifier.toggleSelection
                : null,
            sortField: notifier.query.sortField,
            sortAscending: notifier.query.sortAscending,
            onSort: (field) {
              final q = notifier.query.copyWith(
                sortField: field,
                sortAscending: field == notifier.query.sortField
                    ? !notifier.query.sortAscending
                    : true,
                page: 1,
              );
              notifier.applyQuery(q);
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
                sortField: 'currentLoad',
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
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              if (auth.uiHasExactly(Role.logist) && !w.isDeleted)
                TextButton(
                  onPressed: () => context.go('/warehouses/${w.id}/edit'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Ред.', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiHasExactly(Role.logist) && !w.isDeleted)
                TextButton(
                  onPressed: () => _softDelete(context, w.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    foregroundColor: Colors.orange,
                  ),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiHasExactly(Role.admin) && !w.isDeleted)
                TextButton(
                  onPressed: () => _hardDelete(context, w),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiHasExactly(Role.admin) && w.isDeleted)
                TextButton(
                  onPressed: () => _restore(context, w.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    foregroundColor: Colors.green,
                  ),
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

  Future<void> _softDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть склад?'),
        content: const Text(
          'Склад будет скрыт, но не удалён. Его можно будет восстановить.',
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
    if (!context.mounted) return;

    try {
      final repository = Provider.of<WarehouseRepository>(
        context,
        listen: false,
      );
      await repository.softDelete(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<WarehouseListNotifier>(
      context,
      listen: false,
    );
    await notifier.load();
  }

  Future<void> _hardDelete(BuildContext context, Warehouse w) async {
    // Проверка связей — на клиенте перед запросом.
    if (w.cargoIds.isNotEmpty || w.routeIds.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить склад',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Склад используется в других записях:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (w.cargoIds.isNotEmpty)
                Text(
                  '• Грузов на складе: ${w.cargoIds.length}',
                  style: const TextStyle(fontSize: 14),
                ),
              if (w.routeIds.isNotEmpty)
                Text(
                  '• Маршрутов через склад: ${w.routeIds.length}',
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 12),
              const Text(
                'Сначала удалите или переназначьте связанные записи.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
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
          'Удалить склад навсегда?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Это действие нельзя отменить!',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить навсегда',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final repository = Provider.of<WarehouseRepository>(
        context,
        listen: false,
      );
      await repository.hardDelete(w.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (!context.mounted) return;
    final listNotifier = Provider.of<WarehouseListNotifier>(
      context,
      listen: false,
    );
    await listNotifier.load();
  }

  Future<void> _restore(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить склад?'),
        content: const Text('Склад снова появится в списке.'),
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
      final repository = Provider.of<WarehouseRepository>(
        context,
        listen: false,
      );
      await repository.restore(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<WarehouseListNotifier>(
      context,
      listen: false,
    );
    await notifier.load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WarehouseListNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Скрыть ${notifier.selected.length} складов?',
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
    if (confirmed == true) {
      await notifier.deleteSelected();
    }
  }
}
