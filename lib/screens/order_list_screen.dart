import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/reference_cache.dart';
import '../models/role.dart';
import '../models/order.dart';
import '../state/auth_notifier.dart';
import '../state/order_list_notifier.dart';
import '../state/order_query.dart';
import '../state/load_status.dart';
import '../repositories/order_repository.dart';
import '../repositories/client_repository.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/debounce.dart';
import '../utils/entity_dependencies.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final Debouncer _debouncer = Debouncer();
  Map<String, String> _clientNames = {};

  @override
  void initState() {
    super.initState();
    _loadClientNames();
  }

  Future<void> _loadClientNames() async {
    try {
      final cache = context.read<ReferenceCache>();
      final clientRepo = context.read<ClientRepository>();
      final clients = await cache.load('clients', () => clientRepo.findAll());
      if (!mounted) return;
      setState(() {
        _clientNames = {for (var c in clients) c.id: c.companyName};
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<OrderListNotifier>(context);
    final auth = context.watch<AuthNotifier>();

    return MainScaffold(
      title: 'Заказы',
      currentRoute: '/orders',
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
              onPressed: () => context.go('/orders/create'),
              tooltip: 'Создать заказ',
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
                labelText: 'Поиск по номеру или описанию',
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
                DropdownMenuItem(value: null, child: Text('Все статусы')),
                DropdownMenuItem(
                  value: 'in_transit',
                  child: Text('В пути'),
                ),
                DropdownMenuItem(
                  value: 'delivered',
                  child: Text('Доставлено'),
                ),
                DropdownMenuItem(
                  value: 'cancelled',
                  child: Text('Отменено'),
                ),
              ],
              onChanged: (value) {
                notifier.applyQuery(
                  notifier.query.copyWith(status: value, page: 1),
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
                        'Статус: ${_getStatusText(notifier.query.status!)}',
                      ),
                      onPressed: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(status: null, page: 1),
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
                      notifier.applyQuery(const OrderQuery());
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

  String _getStatusText(String status) {
    switch (status) {
      case 'in_transit':
        return 'В пути';
      case 'delivered':
        return 'Доставлено';
      case 'cancelled':
        return 'Отменено';
      default:
        return status;
    }
  }

  Widget _buildContent(OrderListNotifier notifier, AuthNotifier auth) {
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
          return const EmptyView(message: 'Нет заказов');
        }
        return ResponsiveList<Order>(
          items: notifier.result.items,
          cardBuilder: (order) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                order.orderNumber,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: Text(
                '${order.cargoDescription} | ${_clientNames[order.clientId] ?? 'Клиент ${order.clientId}'}',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              trailing: Text(
                _getStatusText(order.status),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              onTap: () => context.go('/orders/${order.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<Order>(
            items: items,
            idOf: (o) => o.id,
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
                ),
              );
            },
            columns: [
              TableColumnSpec<Order>(
                label: 'Номер',
                sortField: 'orderNumber',
                build: (o) => Text(o.orderNumber),
              ),
              TableColumnSpec<Order>(
                label: 'Клиент',
                build: (o) =>
                    Text(_clientNames[o.clientId] ?? 'ID: ${o.clientId}'),
              ),
              TableColumnSpec<Order>(
                label: 'Описание груза',
                sortField: 'cargoDescription',
                build: (o) => Text(o.cargoDescription),
              ),
              TableColumnSpec<Order>(
                label: 'Вес (кг)',
                sortField: 'weight',
                build: (o) => Text(o.weight.toString()),
              ),
              TableColumnSpec<Order>(
                label: 'Статус',
                build: (o) => Text(_getStatusText(o.status)),
              ),
            ],
            actions: (o) => [
              TextButton(
                onPressed: () => context.go('/orders/${o.id}'),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              if (auth.uiCanEditBusiness && !o.isDeleted)
                TextButton(
                  onPressed: () => context.go('/orders/${o.id}/edit'),
                  child: const Text('Ред.', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanSoftDelete && !o.isDeleted)
                TextButton(
                  onPressed: () => _softDelete(context, o.id),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && !o.isDeleted)
                TextButton(
                  onPressed: () => _hardDelete(context, o),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && o.isDeleted)
                TextButton(
                  onPressed: () => _restore(context, o.id),
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
        title: const Text('Скрыть заказ?'),
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
      final repository = Provider.of<OrderRepository>(context, listen: false);
      await repository.softDelete(id);
      if (!context.mounted) return;
      final notifier = Provider.of<OrderListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _hardDelete(BuildContext context, Order order) async {
    final blockers = await EntityDependencies.forOrder(context, order.id);

    if (blockers.isNotEmpty) {
      if (!context.mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: order.orderNumber,
        blockers: blockers,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заказ навсегда?'),
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
    if (confirmed == true) {
      final repository = Provider.of<OrderRepository>(context, listen: false);
      await repository.hardDelete(order.id);
      if (!context.mounted) return;
      final notifier = Provider.of<OrderListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _restore(BuildContext context, String id) async {
    final repository = Provider.of<OrderRepository>(context, listen: false);
    await repository.restore(id);
    if (!context.mounted) return;
    final notifier = Provider.of<OrderListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OrderListNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить ${notifier.selected.length} заказов?',
        ),
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
    if (confirmed == true) {
      await notifier.deleteSelected();
    }
  }
}
