import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/reference_cache.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../state/order_list_notifier.dart';
import '../models/order.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../utils/debounce.dart';
import '../state/load_status.dart';
import '../state/order_query.dart';
import '../widgets/pagination_controls.dart';
import '../repositories/order_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/cargo_repository.dart';
import '../repositories/route_repository.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final Debouncer _debouncer = Debouncer();
  Map<int, String> _clientNames = {};

  @override
  void initState() {
    super.initState();
    _loadClientNames();
  }

  Future<void> _loadClientNames() async {
    try {
      final cache = context.read<ReferenceCache>();
      final clientRepo = context.read<ClientRepository>();

      // Используем общий кэш: если клиенты уже загружены —
      // запрос к серверу не уйдёт.
      final clients = await cache.load('clients', () => clientRepo.findAll());

      if (!mounted) return;
      setState(() {
        _clientNames = {for (var c in clients) c.id: c.companyName};
      });
    } catch (_) {
      // Игнорируем: имена клиентов — вторичные данные.
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
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
          if (notifier.hasSelection)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, notifier),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
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
              items: [
                const DropdownMenuItem(value: null, child: Text('Все статусы')),
                const DropdownMenuItem(value: 'in_transit', child: Text('В пути')),
                const DropdownMenuItem(value: 'delivered', child: Text('Доставлено')),
                const DropdownMenuItem(value: 'cancelled', child: Text('Отменено')),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (notifier.query.search.isNotEmpty)
                    ActionChip(
                      label: Text('Поиск: ${notifier.query.search}'),
                      onPressed: () {
                        final newQuery = notifier.query.copyWith(search: '', page: 1);
                        notifier.applyQuery(newQuery);
                      },
                    ),
                  if (notifier.query.status != null)
                    ActionChip(
                      label: Text('Статус: ${_getStatusText(notifier.query.status!)}'),
                      onPressed: () {
                        final newQuery = notifier.query.copyWith(status: null, page: 1);
                        notifier.applyQuery(newQuery);
                      },
                    ),
                  if (notifier.query.includeDeleted)
                    ActionChip(
                      label: const Text('Показаны удалённые'),
                      onPressed: () {
                        final newQuery = notifier.query.copyWith(includeDeleted: false, page: 1);
                        notifier.applyQuery(newQuery);
                      },
                    ),
                  ActionChip(
                    label: const Text('Сбросить всё'),
                    onPressed: () {
                      final newQuery = const OrderQuery();
                      notifier.applyQuery(newQuery);
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildContent(notifier, auth),
          ),
          if (notifier.status == LoadStatus.success && notifier.result.total > 0)
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
      floatingActionButton: auth.uiHas(Role.logist)
          ? FloatingActionButton(
              onPressed: () => context.go('/orders/create'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'in_transit': return 'В пути';
      case 'delivered': return 'Доставлено';
      case 'cancelled': return 'Отменено';
      default: return status;
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
              title: Text(order.orderNumber),
              subtitle: Text(
                '${order.cargoDescription} | ${_clientNames[order.clientId] ?? 'Клиент ${order.clientId}'}',
              ),
              trailing: Text(_getStatusText(order.status)),
              onTap: () => context.go('/orders/${order.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<Order>(
            items: items,
            idOf: (o) => o.id,
            selected: notifier.selected,
            onToggleSelect: notifier.toggleSelection,
            sortField: notifier.query.sortField,
            sortAscending: notifier.query.sortAscending,
            onSort: (field) {
              final query = notifier.query.copyWith(
                sortField: field,
                sortAscending: field == notifier.query.sortField
                    ? !notifier.query.sortAscending
                    : true,
              );
              notifier.applyQuery(query);
            },
            columns: [
              TableColumnSpec<Order>(
                label: 'Номер',
                sortField: 'orderNumber',
                build: (o) => Text(o.orderNumber),
              ),
              TableColumnSpec<Order>(
                label: 'Клиент',
                build: (o) => Text(_clientNames[o.clientId] ?? 'ID: ${o.clientId}'),
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
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              if (auth.uiHas(Role.logist))
                TextButton(
                  onPressed: () => context.go('/orders/${o.id}/edit'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Ред.', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiHas(Role.logist))
                TextButton(
                  onPressed: () => _softDelete(context, o.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    foregroundColor: Colors.orange,
                  ),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiHas(Role.admin))
                TextButton(
                  onPressed: () => _hardDelete(context, o.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
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
        title: const Text('Скрыть заказ?'),
        content: const Text('Заказ будет скрыт, но не удалён. Его можно будет восстановить.'),
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

  Future<void> _hardDelete(BuildContext context, int id) async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);
    final order = await orderRepo.findById(id);
    if (order == null || !context.mounted) return;

    final related = <String>[];

    if (order.clientId > 0) {
      final clientRepo = Provider.of<ClientRepository>(context, listen: false);
      final client = await clientRepo.findById(order.clientId);
      if (client != null) {
        related.add('• Клиент: ${client.companyName}');
      }
    }

    if (order.cargoIds.isNotEmpty) {
      final cargoRepo = Provider.of<CargoRepository>(context, listen: false);
      for (final cargoId in order.cargoIds) {
        final cargo = await cargoRepo.findById(cargoId);
        if (cargo != null) {
          related.add('• Груз: ${cargo.name}');
        }
      }
    }

    if (order.routeIds.isNotEmpty) {
      final routeRepo = Provider.of<RouteRepository>(context, listen: false);
      for (final routeId in order.routeIds) {
        final route = await routeRepo.findById(routeId);
        if (route != null) {
          related.add('• Маршрут: ${route.name}');
        }
      }
    }
    if (!context.mounted) return;

    if (related.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить заказ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Этот заказ связан со следующими записями:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...related.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(item, style: const TextStyle(fontSize: 14)),
              )),
              const SizedBox(height: 12),
              Text(
                'Количество связанных записей: ${related.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Сначала удалите или переназначьте связанные записи, затем попробуйте снова.',
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
          'Удалить заказ навсегда?',
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
    if (confirmed == true) {
      final repository = Provider.of<OrderRepository>(context, listen: false);
      await repository.hardDelete(id);
      if (!context.mounted) return;
      final notifier = Provider.of<OrderListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _confirmDelete(BuildContext context, OrderListNotifier notifier) async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);
    final ordersWithRelations = <int>[];

    for (final id in notifier.selected) {
      final order = await orderRepo.findById(id);
      if (order == null) continue;
      if (order.clientId > 0 || order.cargoIds.isNotEmpty || order.routeIds.isNotEmpty) {
        ordersWithRelations.add(id);
      }
    }
    if (!context.mounted) return;

    if (ordersWithRelations.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить заказы',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${ordersWithRelations.length} заказ(ов) имеют связанные записи.\n\n'
            'Сначала удалите или переназначьте связанные записи, затем попробуйте снова.',
            style: const TextStyle(fontSize: 14),
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
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить ${notifier.selected.length} заказов?'),
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
