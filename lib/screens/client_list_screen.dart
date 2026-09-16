import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../state/client_list_notifier.dart';
import '../models/client.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/main_scaffold.dart';
import '../utils/debounce.dart';
import '../state/load_status.dart';
import '../state/client_query.dart';
import '../widgets/pagination_controls.dart';
import '../repositories/client_repository.dart';
import '../repositories/order_repository.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final Debouncer _debouncer = Debouncer();

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<ClientListNotifier>(context);
    final auth = context.watch<AuthNotifier>();

    return MainScaffold(
      title: 'Клиенты',
      currentRoute: '/clients',
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
            tooltip: 'Удалить выбранные',
            onPressed: () => _confirmDelete(context, notifier),
          ),
      ],
      floatingActionButton: auth.uiHas(Role.logist)
          ? FloatingActionButton(
              onPressed: () => context.go('/clients/create'),
              tooltip: 'Создать клиента',
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
                labelText: 'Поиск по компании, контактному лицу или email',
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
          if (notifier.query.hasFilters)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (notifier.query.search.isNotEmpty)
                    ActionChip(
                      label: Text('Поиск: ${notifier.query.search}'),
                      onPressed: () {
                        final newQuery =
                            notifier.query.copyWith(search: '', page: 1);
                        notifier.applyQuery(newQuery);
                      },
                    ),
                  if (notifier.query.includeDeleted)
                    ActionChip(
                      label: const Text('Показаны удалённые'),
                      onPressed: () {
                        final newQuery = notifier.query
                            .copyWith(includeDeleted: false, page: 1);
                        notifier.applyQuery(newQuery);
                      },
                    ),
                  ActionChip(
                    label: const Text('Сбросить всё'),
                    onPressed: () {
                      final newQuery = const ClientQuery();
                      notifier.applyQuery(newQuery);
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildContent(notifier, auth),
          ),
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

  Widget _buildContent(ClientListNotifier notifier, AuthNotifier auth) {
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
          return const EmptyView(message: 'Нет клиентов');
        }
        return ResponsiveList<Client>(
          items: notifier.result.items,
          cardBuilder: (client) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                client.companyName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: Text(
                client.contactPerson,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: Text(
                client.phone,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              onTap: () => context.go('/clients/${client.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<Client>(
            items: items,
            idOf: (c) => c.id,
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
              TableColumnSpec<Client>(
                label: 'Компания',
                sortField: 'companyName',
                build: (c) => Text(c.companyName),
              ),
              TableColumnSpec<Client>(
                label: 'Контактное лицо',
                sortField: 'contactPerson',
                build: (c) => Text(c.contactPerson),
              ),
              TableColumnSpec<Client>(
                label: 'Телефон',
                build: (c) => Text(c.phone),
              ),
            ],
            actions: (c) => [
              TextButton(
                onPressed: () => context.go('/clients/${c.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              if (auth.uiHas(Role.logist))
                TextButton(
                  onPressed: () => context.go('/clients/${c.id}/edit'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Ред.', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiHas(Role.logist))
                TextButton(
                  onPressed: () => _softDelete(context, c.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    foregroundColor: Colors.orange,
                  ),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiHas(Role.admin))
                TextButton(
                  onPressed: () => _hardDelete(context, c.id),
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
        title: const Text('Скрыть клиента?'),
        content: const Text(
            'Клиент будет скрыт, но не удалён. Его можно будет восстановить.'),
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
      final repository =
          Provider.of<ClientRepository>(context, listen: false);
      await repository.softDelete(id);
      if (!context.mounted) return;
      final notifier =
          Provider.of<ClientListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);
    final orders = await orderRepo.findByClientId(id);
    if (!context.mounted) return;

    if (orders.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить клиента',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'У этого клиента есть активные заказы:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...orders.map((order) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '• Заказ #${order.orderNumber} (${order.cargoDescription})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
              const SizedBox(height: 12),
              Text(
                'Количество заказов: ${orders.length}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Сначала удалите или переназначьте заказы, затем попробуйте снова.',
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
          'Удалить клиента навсегда?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Это действие нельзя отменить!\n\n'
          'Все данные клиента будут безвозвратно удалены.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 14)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить навсегда',
                style: TextStyle(fontSize: 14, color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository =
          Provider.of<ClientRepository>(context, listen: false);
      await repository.hardDelete(id);
      if (!context.mounted) return;
      final notifier =
          Provider.of<ClientListNotifier>(context, listen: false);
      await notifier.load();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Клиент удалён навсегда'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, ClientListNotifier notifier) async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);
    final clientsWithOrders = <int>[];

    for (final id in notifier.selected) {
      final orders = await orderRepo.findByClientId(id);
      if (orders.isNotEmpty) {
        clientsWithOrders.add(id);
      }
    }
    if (!context.mounted) return;

    if (clientsWithOrders.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить клиентов',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${clientsWithOrders.length} клиент(ов) имеют активные заказы.\n\n'
            'Сначала удалите или переназначьте заказы, затем попробуйте снова.',
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
        content: Text(
            'Вы уверены, что хотите удалить ${notifier.selected.length} клиентов?'),
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
