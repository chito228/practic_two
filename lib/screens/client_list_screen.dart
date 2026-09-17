import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../models/client.dart';
import '../state/auth_notifier.dart';
import '../state/client_list_notifier.dart';
import '../state/client_query.dart';
import '../state/load_status.dart';
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
        if (notifier.hasSelection && auth.uiCanSoftDelete)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить выбранные',
            onPressed: () => _confirmDelete(context, notifier),
          ),
      ],
      floatingActionButton: auth.uiCanEditBusiness
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
                      notifier.applyQuery(const ClientQuery());
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
            onToggleSelect: auth.uiCanSoftDelete
                ? notifier.toggleSelection
                : null,
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
              if (auth.uiCanEditBusiness && !c.isDeleted)
                TextButton(
                  onPressed: () => context.go('/clients/${c.id}/edit'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Ред.', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanSoftDelete && !c.isDeleted)
                TextButton(
                  onPressed: () => _softDelete(context, c.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    foregroundColor: Colors.orange,
                  ),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && !c.isDeleted)
                TextButton(
                  onPressed: () => _hardDelete(context, c),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && c.isDeleted)
                TextButton(
                  onPressed: () => _restore(context, c.id),
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

  Future<void> _softDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть клиента?'),
        content: const Text(
          'Клиент будет скрыт, но не удалён. Его можно будет восстановить.',
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
      final repository = Provider.of<ClientRepository>(context, listen: false);
      await repository.softDelete(id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
      return;
    }
    if (!context.mounted) return;
    final notifier = Provider.of<ClientListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _hardDelete(BuildContext context, Client client) async {
    final blockers = await EntityDependencies.forClient(context, client.id);

    if (blockers.isNotEmpty) {
      if (!context.mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: client.companyName,
        blockers: blockers,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить клиента навсегда?'),
        content: const Text('Это действие нельзя отменить!'),
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
      final repository = Provider.of<ClientRepository>(context, listen: false);
      await repository.hardDelete(client.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
      return;
    }
    if (!context.mounted) return;
    final notifier = Provider.of<ClientListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _restore(BuildContext context, String id) async {
    if (!context.mounted) return;
    final repository = Provider.of<ClientRepository>(context, listen: false);
    await repository.restore(id);
    if (!context.mounted) return;
    final notifier = Provider.of<ClientListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ClientListNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Скрыть ${notifier.selected.length} клиентов?'),
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
