import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/client_list_notifier.dart';
import '../models/client.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../utils/debounce.dart';
import '../state/load_status.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Клиенты'),
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
                labelText: 'Поиск по компании или контактному лицу',
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (notifier.query.search.isNotEmpty)
                    Chip(
                      label: Text('Поиск: ${notifier.query.search}'),
                      onDeleted: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(search: '', page: 1),
                        );
                      },
                    ),
                  if (notifier.query.includeDeleted)
                    Chip(
                      label: const Text('Показаны удалённые'),
                      onDeleted: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(includeDeleted: false, page: 1),
                        );
                      },
                    ),
                  Chip(
                    label: const Text('Сбросить всё'),
                    onDeleted: () {
                      notifier.applyQuery(
                        notifier.query.copyWith(
                          search: '',
                          includeDeleted: false,
                          page: 1,
                        ),
                      );
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
        onPressed: () => context.go('/clients/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(ClientListNotifier notifier) {
    switch (notifier.status) {
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(child: Text('Ошибка: ${notifier.error}'));
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const Center(child: Text('Нет клиентов'));
        }
        return ResponsiveList<Client>(
          items: notifier.result.items,
          cardBuilder: (client) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(client.name),
              subtitle: Text(client.contactPerson),
              trailing: Text(client.phone),
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
                sortField: 'name',
                build: (c) => Text(c.name),
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
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => context.go('/clients/${c.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/clients/${c.id}/edit'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirmDelete(BuildContext context, ClientListNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить ${notifier.selected.length} клиентов?'),
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
