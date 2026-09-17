import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../state/user_list_notifier.dart';
import '../models/app_user.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/pagination_controls.dart';
import '../utils/debounce.dart';
import '../state/load_status.dart';
import '../repositories/user_repository.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final Debouncer _debouncer = Debouncer();

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<UserListNotifier>(context);
    final auth = context.watch<AuthNotifier>();

    return MainScaffold(
      title: 'Пользователи',
      currentRoute: '/users',
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
      ],
      floatingActionButton: auth.uiHasExactly(Role.admin)
          ? FloatingActionButton(
              onPressed: () => context.go('/users/create'),
              tooltip: 'Создать пользователя',
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
                labelText: 'Поиск по ФИО, логину или email',
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
            child: DropdownButtonFormField<Role>(
              value: notifier.query.role,
              decoration: const InputDecoration(
                labelText: 'Роль',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<Role>(
                  value: null,
                  child: Text('Все роли'),
                ),
                ...Role.values.map(
                  (r) => DropdownMenuItem<Role>(
                    value: r,
                    child: Text(r.label),
                  ),
                ),
              ],
              onChanged: (value) {
                notifier.applyQuery(
                  notifier.query.copyWith(
                    role: value,
                    clearRole: value == null,
                    page: 1,
                  ),
                );
              },
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

  Widget _buildContent(UserListNotifier notifier, AuthNotifier auth) {
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
          return const EmptyView(message: 'Нет пользователей');
        }
        return ResponsiveList<AppUser>(
          items: notifier.result.items,
          cardBuilder: (u) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(u.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('@${u.username} — ${u.email}',
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Text(u.role.label),
              onTap: () => context.go('/users/${u.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<AppUser>(
            items: items,
            idOf: (u) => u.id,
            selected: notifier.selected,
            onToggleSelect: auth.uiHasExactly(Role.admin)
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
              TableColumnSpec<AppUser>(
                label: 'ФИО',
                sortField: 'fullName',
                build: (u) => Text(u.fullName),
              ),
              TableColumnSpec<AppUser>(
                label: 'Логин',
                sortField: 'username',
                build: (u) => Text(u.username),
              ),
              TableColumnSpec<AppUser>(
                label: 'Email',
                sortField: 'email',
                build: (u) => Text(u.email),
              ),
              TableColumnSpec<AppUser>(
                label: 'Роль',
                sortField: 'role',
                build: (u) => Text(u.role.label),
              ),
              TableColumnSpec<AppUser>(
                label: 'Статус',
                build: (u) => Text(u.isDeleted ? 'Скрыт' : 'Активен'),
              ),
            ],
            actions: (u) => [
              TextButton(
                onPressed: () => context.go('/users/${u.id}'),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => context.go('/users/${u.id}/edit'),
                child: const Text('Ред.', style: TextStyle(fontSize: 12)),
              ),
              if (!u.isDeleted)
                TextButton(
                  onPressed: () => _softDelete(context, u.id),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (!u.isDeleted)
                TextButton(
                  onPressed: () => _hardDelete(context, u.id),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
                ),
              if (u.isDeleted)
                TextButton(
                  onPressed: () => _restore(context, u.id),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                  child: const Text('Восстановить', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
    }
  }

  Future<void> _softDelete(BuildContext context, int id) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть пользователя?'),
        content: const Text('Пользователь будет скрыт, войти не сможет.'),
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
    try {
      final r = Provider.of<UserRepository>(context, listen: false);
      await r.softDelete(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (!context.mounted) return;
    final n = Provider.of<UserListNotifier>(context, listen: false);
    await n.load();
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
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
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (c != true) return;
    if (!context.mounted) return;
    try {
      final r = Provider.of<UserRepository>(context, listen: false);
      await r.hardDelete(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (!context.mounted) return;
    final n = Provider.of<UserListNotifier>(context, listen: false);
    await n.load();
  }

  Future<void> _restore(BuildContext context, int id) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить пользователя?'),
        content: const Text('Пользователь снова появится в списке.'),
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
    if (c != true) return;
    if (!context.mounted) return;
    try {
      final r = Provider.of<UserRepository>(context, listen: false);
      await r.restore(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (!context.mounted) return;
    final n = Provider.of<UserListNotifier>(context, listen: false);
    await n.load();
  }
}
