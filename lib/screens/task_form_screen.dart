import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/reference_cache.dart';
import '../models/task.dart';
import '../models/order.dart';
import '../models/route.dart' as model;
import '../models/app_user.dart';
import '../models/role.dart';
import '../repositories/task_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/route_repository.dart';
import '../repositories/user_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/generic_form.dart';
import '../state/task_list_notifier.dart';

class TaskFormScreen extends StatefulWidget {
  final String? id;
  const TaskFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  bool _isLoading = true;
  Task? _task;
  List<AppUser> _logists = [];
  List<Order> _orders = [];
  List<model.Route> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userRepo = context.read<UserRepository>();
      final allUsers = await userRepo.findAll();
      _logists = allUsers.where((u) => u.role == Role.logist).toList();

      final cache = context.read<ReferenceCache>();
      final orderRepo = context.read<OrderRepository>();
      final routeRepo = context.read<RouteRepository>();
      _orders = await cache.load('orders', () => orderRepo.findAll());
      _routes = await cache.load('routes', () => routeRepo.findAll());

      if (widget.isEditing) {
        final repo = context.read<TaskRepository>();
        final t = await repo.findById(widget.id!);
        if (t != null) _task = t;
      } else {
        final currentUser = context.read<AuthNotifier>().user;
        _task = Task(
          id: '',
          title: '',
          description: '',
          priority: TaskPriority.medium,
          status: TaskStatus.newTask,
          createdById: currentUser?.id ?? '',
          assignedToId: _logists.isNotEmpty ? _logists.first.id : '',
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 7)),
        );
      }
    } catch (_) {
      // Игнорируем.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save(Map<String, dynamic> values) async {
    final repo = context.read<TaskRepository>();

    final priorityValue = values['priority'];
    final priority = priorityValue is TaskPriority
        ? priorityValue
        : TaskPriority.fromString(priorityValue?.toString());

    final task = Task(
      id: _task?.id ?? '',
      title: (values['title'] as String?) ?? '',
      description: (values['description'] as String?) ?? '',
      priority: priority,
      status: _task?.status ?? TaskStatus.newTask,
      createdById: _task?.createdById ?? '',
      assignedToId: (values['assignedToId'] as String?) ?? '',
      orderId: values['orderId'] as String?,
      routeId: values['routeId'] as String?,
      createdAt: _task?.createdAt ?? DateTime.now(),
      dueDate: values['dueDate'] as DateTime?,
      isDeleted: _task?.isDeleted ?? false,
    );

    if (widget.isEditing) {
      await repo.update(task);
    } else {
      await repo.create(task);
    }

    if (!mounted) return;
    final notifier = context.read<TaskListNotifier>();
    await notifier.load();
    if (mounted) context.go('/tasks');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Редактирование' : 'Создание'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GenericForm(
      title: widget.isEditing ? 'Редактирование задачи' : 'Создание задачи',
      isEditing: widget.isEditing,
      initialValues: {
        'title': _task?.title ?? '',
        'description': _task?.description ?? '',
        'priority': _task?.priority ?? TaskPriority.medium,
        'assignedToId': _task?.assignedToId,
        'orderId': _task?.orderId,
        'routeId': _task?.routeId,
        'dueDate': _task?.dueDate,
      },
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Название задачи',
          maxLength: 200,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Описание',
          maxLines: 4,
          maxLength: 1000,
        ),
        FormFieldConfig(
          key: 'priority',
          label: 'Приоритет',
          type: FormFieldType.dropdown,
          options: TaskPriority.values
              .map(
                (p) => DropdownMenuItem<TaskPriority>(
                  value: p,
                  child: Text(p.label),
                ),
              )
              .toList(),
        ),
        FormFieldConfig(
          key: 'assignedToId',
          label: 'Исполнитель (логист)',
          type: FormFieldType.dropdown,
          options: _logists
              .map(
                (u) => DropdownMenuItem<String>(
                  value: u.id,
                  child: Text(u.fullName),
                ),
              )
              .toList(),
        ),
        FormFieldConfig(
          key: 'orderId',
          label: 'Связанный заказ (опционально)',
          type: FormFieldType.dropdown,
          required: false,
          options: _orders
              .map(
                (o) => DropdownMenuItem<String>(
                  value: o.id,
                  child: Text(o.orderNumber),
                ),
              )
              .toList(),
        ),
        FormFieldConfig(
          key: 'routeId',
          label: 'Связанный маршрут (опционально)',
          type: FormFieldType.dropdown,
          required: false,
          options: _routes
              .map(
                (r) => DropdownMenuItem<String>(
                  value: r.id,
                  child: Text(r.name),
                ),
              )
              .toList(),
        ),
        FormFieldConfig(
          key: 'dueDate',
          label: 'Срок (опционально)',
          type: FormFieldType.date,
          required: false,
        ),
      ],
      onSubmit: _save,
      onCancel: () => context.go('/tasks'),
    );
  }
}
