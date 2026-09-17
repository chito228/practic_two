import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../models/task.dart';
import '../models/app_user.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';
import '../state/auth_notifier.dart';
import '../state/task_list_notifier.dart';

class TaskDetailScreen extends StatelessWidget {
  final String id;
  const TaskDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<TaskRepository>(context);
    final auth = context.watch<AuthNotifier>();

    return FutureBuilder<Task?>(
      future: repository.findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Задача')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Задача')),
            body: const Center(child: Text('Задача не найдена')),
          );
        }
        final t = snapshot.data!;
        return FutureBuilder<List<AppUser>>(
          future: context.read<UserRepository>().findAll(),
          builder: (context, usersSnap) {
            final users = usersSnap.data ?? <AppUser>[];
            String userName(String id) {
              try {
                return users.firstWhere((u) => u.id == id).fullName;
              } catch (_) {
                return 'ID: $id';
              }
            }

            // Кто может менять статус:
            //   - logist: только для своих переходов;
            //   - manager/admin: без ограничений.
            // Здесь оставляем строго логиста, чтобы не ломать бизнес-логику.
            final canChangeStatus =
                auth.uiHasExactly(Role.logist) && !t.isDeleted;

            return Scaffold(
              appBar: AppBar(title: Text(t.title)),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('ID', t.id),
                      _infoRow('Название', t.title),
                      _infoRow('Описание', t.description),
                      _infoRow('Приоритет', t.priority.label),

                      // ─── Статус: dropdown для логиста, текст для остальных ───
                      if (canChangeStatus)
                        _statusDropdown(context, t)
                      else
                        _infoRow('Статус', t.status.label),

                      _infoRow('Создана', userName(t.createdById)),
                      _infoRow('Назначена', userName(t.assignedToId)),
                      _infoRow(
                        'Дата создания',
                        t.createdAt.toLocal().toString().split(' ')[0],
                      ),
                      if (t.dueDate != null)
                        _infoRow(
                          'Срок',
                          t.dueDate!.toLocal().toString().split(' ')[0],
                          color: t.isOverdue ? Colors.red : Colors.black,
                        ),
                      if (t.resolution != null && t.resolution!.isNotEmpty)
                        _infoRow('Резолюция', t.resolution!),
                      if (t.isDeleted)
                        _infoRow('Статус', 'Скрыта', color: Colors.orange),

                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.go('/tasks'),
                            child: const Text('Назад'),
                          ),
                          if (auth.uiCanEditTasks &&
                              t.status == TaskStatus.newTask)
                            ElevatedButton(
                              onPressed: () =>
                                  context.go('/tasks/${t.id}/edit'),
                              child: const Text('Редактировать'),
                            ),
                          if (auth.uiCanHardDelete)
                            ElevatedButton(
                              onPressed: () => _hardDelete(context, t.id),
                              child: const Text('Удалить'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Компактный выпадающий список статуса для логиста.
  /// Ширина ограничена 220 px, чтобы не растягивался на всю строку.
  Widget _statusDropdown(BuildContext context, Task t) {
    final options = _allowedStatuses(t.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 140,
            child: Text(
              'Статус:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: DropdownButtonFormField<TaskStatus>(
              value: t.status,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: options
                  .map(
                    (s) => DropdownMenuItem<TaskStatus>(
                      value: s,
                      child: Text(
                        s.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (newStatus) {
                if (newStatus == null || newStatus == t.status) return;
                _changeStatus(context, t, newStatus);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Допустимые переходы из текущего статуса.
  /// В список всегда включаем текущий статус, чтобы dropdown
  /// показывал актуальное значение.
  List<TaskStatus> _allowedStatuses(TaskStatus current) {
    switch (current) {
      case TaskStatus.newTask:
        return const [TaskStatus.newTask, TaskStatus.inProgress];
      case TaskStatus.inProgress:
        return const [
          TaskStatus.inProgress,
          TaskStatus.done,
          TaskStatus.rejected,
        ];
      case TaskStatus.done:
      case TaskStatus.rejected:
        // Из финальных статусов переходов нет — только текущий.
        return [current];
    }
  }

  Widget _infoRow(String label, String value, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
              overflow: TextOverflow.ellipsis,
              maxLines: 5,
            ),
          ),
        ],
      ),
    );
  }

  /// Смена статуса. Для `done` и `rejected` — диалог с комментарием.
  Future<void> _changeStatus(
    BuildContext context,
    Task task,
    TaskStatus newStatus,
  ) async {
    String? resolution;
    if (newStatus == TaskStatus.done || newStatus == TaskStatus.rejected) {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Смена статуса: ${newStatus.label}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Комментарий',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      );
      if (result == null) return;
      resolution = result;
    }

    if (!context.mounted) return;
    try {
      final repo = Provider.of<TaskRepository>(context, listen: false);
      await repo.update(
        task.copyWith(
          status: newStatus,
          resolution: resolution ?? task.resolution,
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<TaskListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Статус изменён на «${newStatus.label}»')),
    );
  }

  Future<void> _hardDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
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

    try {
      final repo = Provider.of<TaskRepository>(context, listen: false);
      await repo.hardDelete(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<TaskListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/tasks');
  }
}
