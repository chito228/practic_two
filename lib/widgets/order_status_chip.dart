import 'package:flutter/material.dart';

/// Единый виджет для отображения статуса заказа.
/// Используется в диспетчерской, чтобы цвета статусов
/// совпадали с цветами канбана.
class OrderStatusChip extends StatelessWidget {
  final String status;
  final bool compact;

  const OrderStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.fg,
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _ChipStyle _styleFor(String status) {
    switch (status) {
      case 'in_transit':
        return const _ChipStyle(
          label: 'В пути',
          bg: Color(0xFFE3F2FD),
          fg: Color(0xFF0D47A1),
          border: Color(0xFF90CAF9),
        );
      case 'delivered':
        return const _ChipStyle(
          label: 'Доставлено',
          bg: Color(0xFFE8F5E9),
          fg: Color(0xFF1B5E20),
          border: Color(0xFFA5D6A7),
        );
      case 'cancelled':
        return const _ChipStyle(
          label: 'Отменено',
          bg: Color(0xFFFFEBEE),
          fg: Color(0xFFB71C1C),
          border: Color(0xFFEF9A9A),
        );
      default:
        return _ChipStyle(
          label: status,
          bg: Colors.grey.shade100,
          fg: Colors.grey.shade800,
          border: Colors.grey.shade300,
        );
    }
  }
}

class _ChipStyle {
  final String label;
  final Color bg;
  final Color fg;
  final Color border;

  const _ChipStyle({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });
}
