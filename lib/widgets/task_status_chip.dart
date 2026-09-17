import 'package:flutter/material.dart';

import '../models/task.dart';

/// Чип статуса задачи.
/// Отображается как текст определённого цвета — без фона и рамки.
class TaskStatusChip extends StatelessWidget {
  final TaskStatus status;
  final bool compact;

  const TaskStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Text(
      style.label,
      style: TextStyle(
        color: style.color,
        fontSize: compact ? 12 : 14,
        fontWeight: FontWeight.w600,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  _ChipStyle _styleFor(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return const _ChipStyle(
          label: 'Новая',
          color: Color(0xFF0D47A1), // синий
        );
      case TaskStatus.inProgress:
        return const _ChipStyle(
          label: 'В работе',
          color: Color(0xFFE65100), // оранжевый
        );
      case TaskStatus.done:
        return const _ChipStyle(
          label: 'Выполнена',
          color: Color(0xFF1B5E20), // зелёный
        );
      case TaskStatus.rejected:
        return const _ChipStyle(
          label: 'Отклонена',
          color: Color(0xFFB71C1C), // красный
        );
    }
  }
}

class _ChipStyle {
  final String label;
  final Color color;

  const _ChipStyle({
    required this.label,
    required this.color,
  });
}
