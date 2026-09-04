import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/order_list_notifier.dart';
import '../models/order.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../utils/debounce.dart';
import '../state/load_status.dart';
import '../state/order_query.dart'; 

class OrderListScreen extends StatefulWidget {
  final Map<String, String> initialQuery;
  const OrderListScreen({super.key, this.initialQuery = const {}});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final Debouncer _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    final query = widget.initialQuery;
    final notifier = Provider.of<OrderListNotifier>(context, listen: false);
    notifier.applyQuery(
      OrderQuery(
        search: query['search'] ?? '',
        status: query['status'],
        clientId: int.tryParse(query['clientId'] ?? ''),
        dateFrom: query['dateFrom'] != null ? DateTime.tryParse(query['dateFrom']!) : null,
        dateTo: query['dateTo'] != null ? DateTime.tryParse(query['dateTo']!) : null,
        sortField: query['sort'] ?? 'cargoDescription',
        sortAscending: query['order'] != 'desc',
        page: int.tryParse(query['page'] ?? '1') ?? 1,
        size: int.tryParse(query['size'] ?? '10') ?? 10,
        includeDeleted: query['deleted'] == 'true',
      ),
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<OrderListNotifier>(context);

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
                    final query = notifier.query.copyWith(includeDeleted: value, page: 1);
                    _updateUrl(query);
                    notifier.applyQuery(query);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Поиск заказов',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _debouncer.call(() {
                  final query = notifier.query.copyWith(search: value, page: 1);
                  _updateUrl(query);
                  notifier.applyQuery(query);
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
                ...['в пути', 'доставлено', 'отменено'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                final query = notifier.query.copyWith(status: value, page: 1);
                _updateUrl(query);
                notifier.applyQuery(query);
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'ID клиента',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (value) {
                      final id = int.tryParse(value);
                      final query = notifier.query.copyWith(clientId: id, page: 1);
                      _updateUrl(query);
                      notifier.applyQuery(query);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        final query = notifier.query.copyWith(dateFrom: date, page: 1);
                        _updateUrl(query);
                        notifier.applyQuery(query);
                      }
                    },
                    child: Text(
                      notifier.query.dateFrom != null
                          ? 'С: ${notifier.query.dateFrom!.toLocal().toString().split(' ')[0]}'
                          : 'Дата от',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        final query = notifier.query.copyWith(dateTo: date, page: 1);
                        _updateUrl(query);
                        notifier.applyQuery(query);
                      }
                    },
                    child: Text(
                      notifier.query.dateTo != null
                          ? 'По: ${notifier.query.dateTo!.toLocal().toString().split(' ')[0]}'
                          : 'Дата до',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (notifier.query.hasFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (notifier.query.status != null)
                    Chip(
                      label: Text('Статус: ${notifier.query.status}'),
                      onDeleted: () {
                        final query = notifier.query.copyWith(status: null, page: 1);
                        _updateUrl(query);
                        notifier.applyQuery(query);
                      },
                    ),
                  if (notifier.query.clientId != null)
                    Chip(
                      label: Text('Клиент ID: ${notifier.query.clientId}'),
                      onDeleted: () {
                        final query = notifier.query.copyWith(clientId: null, page: 1);
                        _updateUrl(query);
                        notifier.applyQuery(query);
                      },
                    ),
                  if (notifier.query.dateFrom != null)
                    Chip(
                      label: Text('С: ${notifier.query.dateFrom!.toLocal().toString().split(' ')[0]}'),
                      onDeleted: () {
                        final query = notifier.query.copyWith(dateFrom: null, page: 1);
                        _updateUrl(query);
                        notifier.applyQuery(query);
                      },
                    ),
                  if (notifier.query.dateTo != null)
                    Chip(
                      label: Text('По: ${notifier.query.dateTo!.toLocal().toString().split(' ')[0]}'),
                      onDeleted: () {
                        final query = notifier.query.copyWith(dateTo: null, page: 1);
                        _updateUrl(query);
                        notifier.applyQuery(query);
                      },
                    ),
                  Chip(
                    label: const Text('Сбросить всё'),
                    onDeleted: () {
                      final query = notifier.query.copyWith(
                        status: null,
                        clientId: null,
                        dateFrom: null,
                        dateTo: null,
                        search: '',
                        page: 1,
                      );
                      _updateUrl(query);
                      notifier.applyQuery(query);
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildContent(notifier),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/orders/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(OrderListNotifier notifier) {
    switch (notifier.status) {
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(child: Text('Ошибка: ${notifier.error}'));
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const Center(child: Text('Нет заказов'));
        }
        return ResponsiveList<Order>(
          items: notifier.result.items,
          cardBuilder: (order) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(order.cargoDescription),
              subtitle: Text('Статус: ${order.status}'),
              trailing: Text('${order.weight} кг'),
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
              _updateUrl(query);
              notifier.applyQuery(query);
            },
            columns: [
              TableColumnSpec<Order>(
                label: 'Груз',
                sortField: 'cargoDescription',
                build: (o) => Text(o.cargoDescription),
              ),
              TableColumnSpec<Order>(
                label: 'Вес (кг)',
                sortField: 'weight',
                numeric: true,
                build: (o) => Text(o.weight.toString()),
              ),
              TableColumnSpec<Order>(
                label: 'Дата отправки',
                sortField: 'sendDate',
                build: (o) => Text(o.sendDate.toLocal().toString().split(' ')[0]),
              ),
              TableColumnSpec<Order>(
                label: 'Статус',
                build: (o) => Text(o.status),
              ),
            ],
            actions: (o) => [
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => context.go('/orders/${o.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/orders/${o.id}/edit'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _updateUrl(OrderQuery query) {
    final params = <String, String>{};
    if (query.search.isNotEmpty) params['search'] = query.search;
    if (query.status != null) params['status'] = query.status!;
    if (query.clientId != null) params['clientId'] = query.clientId.toString();
    if (query.dateFrom != null) params['dateFrom'] = query.dateFrom!.toIso8601String();
    if (query.dateTo != null) params['dateTo'] = query.dateTo!.toIso8601String();
    if (query.sortField != 'cargoDescription') params['sort'] = query.sortField;
    if (!query.sortAscending) params['order'] = 'desc';
    if (query.page > 1) params['page'] = query.page.toString();
    if (query.size != 10) params['size'] = query.size.toString();
    if (query.includeDeleted) params['deleted'] = 'true';

    final uri = Uri(path: '/orders', queryParameters: params);
    context.replace(uri.toString());
  }

  Future<void> _confirmDelete(BuildContext context, OrderListNotifier notifier) async {
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
