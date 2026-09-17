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
import '../widgets/task_status_chip.dart';

class TaskDetailScreen extends StatelessWidget {
  final int id;
  const TaskDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<TaskRepository>(context);
    final auth = context.watch<AuthNotifier>();

    return FutureBuilder(
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
            String userName(int id) {
              try {
                return users.firstWhere((u) => u.id == id).fullName;
              } catch (_) {
                return 'ID: $id';
              }
            }

            return Scaffold(
              appBar: AppBar(title: Text(t.title)),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('ID', t.id.toString()),
                      _infoRow('Название', t.title),
                      _infoRow('Описание', t.description),
                      _infoRow('Приоритет', t.priority.label),
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
                          // «Назад» — все роли.
                          ElevatedButton(
                            onPressed: () => context.go('/tasks'),
                            child: const Text('Назад'),
                          ),
                          // «Редактировать» — только manager (не logist).
                          if (auth.uiHasExactly(Role.manager) &&
                              t.status == TaskStatus.newTask)
                            ElevatedButton(
                              onPressed: () =>
                                  context.go('/tasks/${t.id}/edit'),
                              child: const Text('Редактировать'),
                            ),
                          // «Взять в работу» — только logist.
                          if (auth.uiHasExactly(Role.logist) &&
                              t.status == TaskStatus.newTask)
                            ElevatedButton(
                              onPressed: () => _changeStatus(
                                context,
                                t,
                                TaskStatus.inProgress,
                              ),
                              child: const Text('Взять в работу'),
                            ),
                          // «Выполнено» — только logist.
                          if (auth.uiHasExactly(Role.logist) &&
                              t.status == TaskStatus.inProgress)
                            ElevatedButton(
                              onPressed: () =>
                                  _changeStatus(context, t, TaskStatus.done),
                              child: const Text('Выполнено'),
                            ),
                          // «Отклонить» — только logist.
                          if (auth.uiHasExactly(Role.logist) &&
                              t.status == TaskStatus.inProgress)
                            ElevatedButton(
                              onPressed: () => _changeStatus(
                                context,
                                t,
                                TaskStatus.rejected,
                              ),
                              child: const Text('Отклонить'),
                            ),
                          // «Удалить» — только admin.
                          if (auth.uiHasExactly(Role.admin))
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

  Future<void> _changeStatus(
    BuildContext context,
    Task task,
    TaskStatus newStatus,
  ) async {
    String? resolution;
    if (newStatus == TaskStatus.done ||
        newStatus == TaskStatus.rejected) {
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
    context.go('/tasks');
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
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
