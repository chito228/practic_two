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

/// Статус задачи.
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
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final String createdById;
  final String assignedToId;
  final String? orderId;
  final String? routeId;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? resolution;
  final bool isDeleted;

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
    this.isDeleted = false,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == TaskStatus.done || status == TaskStatus.rejected) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    String? createdById,
    String? assignedToId,
    String? orderId,
    String? routeId,
    bool clearOrder = false,
    bool clearRoute = false,
    DateTime? createdAt,
    DateTime? dueDate,
    String? resolution,
    bool? isDeleted,
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
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    priority: TaskPriority.fromString(json['priority'] as String?),
    status: TaskStatus.fromString(json['status'] as String?),
    createdById: json['createdBy'] as String? ?? '',
    assignedToId: json['assignedTo'] as String? ?? '',
    orderId: json['order'] as String?,
    routeId: json['route'] as String?,
    createdAt: json['created'] == null
        ? DateTime.now()
        : DateTime.parse(json['created'] as String),
    dueDate: json['dueDate'] == null
        ? null
        : DateTime.parse(json['dueDate'] as String),
    resolution: (json['resolution'] as String?)?.isEmpty == true
        ? null
        : json['resolution'] as String?,
    isDeleted: json['deleted'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'priority': priority.toJson(),
    'status': status.toJson(),
    'createdBy': createdById,
    'assignedTo': assignedToId,
    'order': orderId,
    'route': routeId,
    'dueDate': dueDate?.toIso8601String(),
    'resolution': resolution,
  };
}
