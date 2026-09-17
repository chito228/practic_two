/// Приоритет задачи.
enum TaskPriority {
  low('Низкий'),
  medium('Средний'),
  high('Высокий');

  final String label;
  const TaskPriority(this.label);

  static TaskPriority fromString(String? value) {
    switch (value) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  String toJson() => name;
}

/// Статус задачи (workflow).
enum TaskStatus {
  newTask('Новая'),
  inProgress('В работе'),
  done('Выполнена'),
  rejected('Отклонена');

  final String label;
  const TaskStatus(this.label);

  static TaskStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'rejected':
        return TaskStatus.rejected;
      default:
        return TaskStatus.newTask;
    }
  }

  String toJson() {
    switch (this) {
      case TaskStatus.newTask:
        return 'new';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.rejected:
        return 'rejected';
    }
  }
}

class Task {
  final int id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final int createdById;
  final int assignedToId;
  final int? orderId;
  final int? routeId;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? resolution;
  final DateTime? deletedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdById,
    required this.assignedToId,
    this.orderId,
    this.routeId,
    required this.createdAt,
    this.dueDate,
    this.resolution,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  /// Просрочена ли задача.
  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == TaskStatus.done || status == TaskStatus.rejected) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  /// Можно ли перевести задачу в новый статус для роли.
  bool canTransition(
    TaskStatus to, {
    required bool isManager,
    required bool isLogist,
  }) {
    if (isManager) {
      return status == TaskStatus.newTask && to == TaskStatus.newTask;
    }
    if (isLogist) {
      if (status == TaskStatus.newTask && to == TaskStatus.inProgress) {
        return true;
      }
      if (status == TaskStatus.inProgress && to == TaskStatus.done) {
        return true;
      }
      if (status == TaskStatus.inProgress && to == TaskStatus.rejected) {
        return true;
      }
      return false;
    }
    return true; // admin
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    int? createdById,
    int? assignedToId,
    int? orderId,
    int? routeId,
    bool clearOrder = false,
    bool clearRoute = false,
    DateTime? createdAt,
    DateTime? dueDate,
    String? resolution,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdById: createdById ?? this.createdById,
      assignedToId: assignedToId ?? this.assignedToId,
      orderId: clearOrder ? null : (orderId ?? this.orderId),
      routeId: clearRoute ? null : (routeId ?? this.routeId),
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      resolution: resolution ?? this.resolution,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority.toJson(),
    'status': status.toJson(),
    'createdById': createdById,
    'assignedToId': assignedToId,
    'orderId': orderId,
    'routeId': routeId,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'resolution': resolution,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    priority: TaskPriority.fromString(json['priority'] as String?),
    status: TaskStatus.fromString(json['status'] as String?),
    createdById: json['createdById'] as int? ?? 0,
    assignedToId: json['assignedToId'] as int? ?? 0,
    orderId: json['orderId'] as int?,
    routeId: json['routeId'] as int?,
    createdAt: json['createdAt'] == null
        ? DateTime.now()
        : DateTime.parse(json['createdAt'] as String),
    dueDate: json['dueDate'] == null
        ? null
        : DateTime.parse(json['dueDate'] as String),
    resolution: json['resolution'] as String?,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
  );
}
