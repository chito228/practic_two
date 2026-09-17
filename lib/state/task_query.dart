/// Параметры запроса списка задач.
class TaskQuery {
  final String search;
  final String? status;
  final String? priority;
  final String? createdById;    // было int?
  final String? assignedToId;   // было int?
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const TaskQuery({
    this.search = '',
    this.status,
    this.priority,
    this.createdById,
    this.assignedToId,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  TaskQuery copyWith({
    String? search,
    String? status,
    String? priority,
    String? createdById,
    String? assignedToId,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearCreatedBy = false,
    bool clearAssignedTo = false,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return TaskQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      createdById: clearCreatedBy ? null : (createdById ?? this.createdById),
      assignedToId:
          clearAssignedTo ? null : (assignedToId ?? this.assignedToId),
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  bool get hasFilters =>
      search.isNotEmpty ||
      status != null ||
      priority != null ||
      createdById != null ||
      assignedToId != null ||
      includeDeleted;
}
