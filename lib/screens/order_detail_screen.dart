import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../repositories/order_repository.dart';
import '../state/auth_notifier.dart';
import '../state/order_list_notifier.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/entity_dependencies.dart';

class OrderDetailScreen extends StatelessWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<OrderRepository>(context);
    final auth = context.watch<AuthNotifier>();

    return FutureBuilder<OrderFull?>(
      future: repository.findByIdWithRelations(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Заказ')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Заказ')),
            body: const Center(child: Text('Заказ не найден')),
          );
        }

        final full = snapshot.data!;
        final order = full.order;
        final client = full.client;
        final cargoList = full.cargo;
        final routeList = full.routes;

        return Scaffold(
          appBar: AppBar(title: Text('Заказ #${order.orderNumber}')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('ID', order.id),
                  _infoRow('Номер заказа', order.orderNumber),
                  _infoRow(
                    'Клиент',
                    client?.companyName ?? 'ID: ${order.clientId}',
                  ),
                  _infoRow('Описание груза', order.cargoDescription),
                  _infoRow('Вес', '${order.weight} кг'),
                  _infoRow('Объём', '${order.volume} м³'),
                  _infoRow(
                    'Дата отправки',
                    order.shippingDate.toLocal().toString().split(' ')[0],
                  ),
                  if (order.deliveryDate != null)
                    _infoRow(
                      'Дата доставки',
                      order.deliveryDate!.toLocal().toString().split(' ')[0],
                    ),
                  _infoRow('Статус', _getStatusText(order.status)),

                  const Divider(height: 32),
                  const Text(
                    'Грузы',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (cargoList.isNotEmpty)
                    ...cargoList.map((c) => _infoRow('•', c.name))
                  else
                    const Text(
                      'Нет грузов',
                      style: TextStyle(color: Colors.grey),
                    ),

                  const Divider(height: 32),
                  const Text(
                    'Маршруты',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (routeList.isNotEmpty)
                    ...routeList.map((r) => _infoRow('•', r.name))
                  else
                    const Text(
                      'Нет маршрутов',
                      style: TextStyle(color: Colors.grey),
                    ),

                  if (order.isDeleted)
                    _infoRow('Статус', 'Скрыт', color: Colors.orange),

                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/orders'),
                        child: const Text('Назад'),
                      ),
                      if (auth.uiCanEditBusiness && !order.isDeleted)
                        ElevatedButton(
                          onPressed: () =>
                              context.go('/orders/${order.id}/edit'),
                          child: const Text('Редактировать'),
                        ),
                      if (!order.isDeleted) ...[
                        if (auth.uiCanSoftDelete)
                          ElevatedButton(
                            onPressed: () => _softDelete(context, order.id),
                            child: const Text('Скрыть'),
                          ),
                        if (auth.uiCanHardDelete)
                          ElevatedButton(
                            onPressed: () => _hardDelete(context, order),
                            child: const Text('Удалить'),
                          ),
                      ] else ...[
                        if (auth.uiCanHardDelete)
                          ElevatedButton(
                            onPressed: () => _restore(context, order.id),
                            child: const Text('Восстановить'),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'in_transit':
        return 'В пути';
      case 'delivered':
        return 'Доставлено';
      case 'cancelled':
        return 'Отменено';
      default:
        return status;
    }
  }

  Widget _infoRow(String label, String value, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: label.length > 2 ? 120 : 20,
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
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _softDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть заказ?'),
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
    final repository = Provider.of<OrderRepository>(context, listen: false);
    await repository.softDelete(id);
    if (!context.mounted) return;
    final notifier = Provider.of<OrderListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/orders');
  }

  Future<void> _hardDelete(BuildContext context, dynamic order) async {
    final blockers = await EntityDependencies.forOrder(context, order.id);

    if (blockers.isNotEmpty) {
      if (!context.mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: order.orderNumber,
        blockers: blockers,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить навсегда?'),
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
    final repository = Provider.of<OrderRepository>(context, listen: false);
    await repository.hardDelete(order.id);
    if (!context.mounted) return;
    final notifier = Provider.of<OrderListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/orders');
  }

  Future<void> _restore(BuildContext context, String id) async {
    if (!context.mounted) return;
    final repository = Provider.of<OrderRepository>(context, listen: false);
    await repository.restore(id);
    if (!context.mounted) return;
    final notifier = Provider.of<OrderListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/orders');
  }
}
