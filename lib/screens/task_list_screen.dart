import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../models/task.dart';
import '../state/auth_notifier.dart';
import '../state/task_list_notifier.dart';
import '../state/task_query.dart';
import '../state/load_status.dart';
import '../repositories/task_repository.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/task_status_chip.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/debounce.dart';
import '../utils/entity_dependencies.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final Debouncer _debouncer = Debouncer();

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<TaskListNotifier>(context);
    final auth = context.watch<AuthNotifier>();

    return MainScaffold(
      title: 'Задачи',
      currentRoute: '/tasks',
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
        if (notifier.hasSelection && auth.uiCanHardDelete)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить выбранные',
            onPressed: () => _confirmDelete(context, notifier),
          ),
      ],
      floatingActionButton: auth.uiCanEditTasks
          ? FloatingActionButton(
              onPressed: () => context.go('/tasks/create'),
              tooltip: 'Создать задачу',
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
                labelText: 'Поиск по названию или описанию',
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
                      DropdownMenuItem(value: 'new', child: Text('Новая')),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('В работе'),
                      ),
                      DropdownMenuItem(
                        value: 'done',
                        child: Text('Выполнена'),
                      ),
                      DropdownMenuItem(
                        value: 'rejected',
                        child: Text('Отклонена'),
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
                    value: notifier.query.priority,
                    decoration: const InputDecoration(
                      labelText: 'Приоритет',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все')),
                      DropdownMenuItem(value: 'low', child: Text('Низкий')),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Средний'),
                      ),
                      DropdownMenuItem(value: 'high', child: Text('Высокий')),
                    ],
                    onChanged: (value) {
                      notifier.applyQuery(
                        notifier.query.copyWith(
                          priority: value,
                          clearPriority: value == null,
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
                      label: Text('Статус: ${notifier.query.status}'),
                      onPressed: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(
                            clearStatus: true,
                            page: 1,
                          ),
                        );
                      },
                    ),
                  if (notifier.query.priority != null)
                    ActionChip(
                      label: Text('Приоритет: ${notifier.query.priority}'),
                      onPressed: () {
                        notifier.applyQuery(
                          notifier.query.copyWith(
                            clearPriority: true,
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
                      notifier.applyQuery(const TaskQuery());
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

  Widget _buildContent(TaskListNotifier notifier, AuthNotifier auth) {
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
          return const EmptyView(message: 'Нет задач');
        }
        return ResponsiveList<Task>(
          items: notifier.result.items,
          cardBuilder: (t) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                t.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: Text(
                t.description,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t.isOverdue)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.warning_amber,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  TaskStatusChip(status: t.status, compact: true),
                ],
              ),
              onTap: () => context.go('/tasks/${t.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<Task>(
            items: items,
            idOf: (t) => t.id,
            selected: notifier.selected,
            onToggleSelect: auth.uiCanHardDelete
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
              TableColumnSpec<Task>(
                label: 'Название',
                sortField: 'title',
                build: (t) => Text(t.title),
              ),
              TableColumnSpec<Task>(
                label: 'Приоритет',
                sortField: 'priority',
                build: (t) => Text(t.priority.label),
              ),
              TableColumnSpec<Task>(
                label: 'Статус',
                build: (t) => TaskStatusChip(status: t.status, compact: true),
              ),
              TableColumnSpec<Task>(
                label: 'Срок',
                sortField: 'dueDate',
                build: (t) => Text(
                  t.dueDate == null
                      ? '—'
                      : t.dueDate!.toLocal().toString().split(' ')[0],
                ),
              ),
            ],
            actions: (t) => [
              TextButton(
                onPressed: () => context.go('/tasks/${t.id}'),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              if (auth.uiCanEditTasks && !t.isDeleted)
                TextButton(
                  onPressed: () => context.go('/tasks/${t.id}/edit'),
                  child: const Text('Ред.', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanEditTasks && !t.isDeleted)
                TextButton(
                  onPressed: () => _softDelete(context, t.id),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && !t.isDeleted)
                TextButton(
                  onPressed: () => _hardDelete(context, t),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
                ),
              if (auth.uiCanHardDelete && t.isDeleted)
                TextButton(
                  onPressed: () => _restore(context, t.id),
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
        title: const Text('Скрыть задачу?'),
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
    final repository = Provider.of<TaskRepository>(context, listen: false);
    await repository.softDelete(id);
    if (!context.mounted) return;
    final notifier = Provider.of<TaskListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _hardDelete(BuildContext context, Task task) async {
    final blockers = await EntityDependencies.forTask(context, task.id);

    if (blockers.isNotEmpty) {
      if (!context.mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: task.title,
        blockers: blockers,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу навсегда?'),
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
    final repository = Provider.of<TaskRepository>(context, listen: false);
    await repository.hardDelete(task.id);
    if (!context.mounted) return;
    final notifier = Provider.of<TaskListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _restore(BuildContext context, String id) async {
    final repository = Provider.of<TaskRepository>(context, listen: false);
    await repository.restore(id);
    if (!context.mounted) return;
    final notifier = Provider.of<TaskListNotifier>(context, listen: false);
    await notifier.load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TaskListNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить ${notifier.selected.length} задач?'),
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
