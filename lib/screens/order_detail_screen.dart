import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/persistent_order_repository.dart';
import '../repositories/persistent_client_repository.dart';
import '../repositories/persistent_cargo_repository.dart';
import '../repositories/persistent_route_repository.dart';
import '../state/order_list_notifier.dart';
import '../models/order.dart';
import '../models/client.dart';
import '../models/cargo.dart';
import '../models/route.dart' as model;

class OrderDetailScreen extends StatelessWidget {
  final int id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<PersistentOrderRepository>(context);
    return FutureBuilder(
      future: repository.findById(id),
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
        final order = snapshot.data!;

        return FutureBuilder(
          future: Future.wait([
            context.read<PersistentClientRepository>().findById(order.clientId),
            Future.wait(order.cargoIds.map((id) =>
              context.read<PersistentCargoRepository>().findById(id))),
            Future.wait(order.routeIds.map((id) =>
              context.read<PersistentRouteRepository>().findById(id))),
          ]),
          builder: (context, relatedSnapshot) {
            if (relatedSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: Text('Заказ #${order.orderNumber}')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final client = relatedSnapshot.data?[0] as Client?;
            final cargoList = (relatedSnapshot.data?[1] as List?)?.whereType<Cargo>().toList() ?? [];
            final routeList = (relatedSnapshot.data?[2] as List?)?.whereType<model.Route>().toList() ?? [];

            return Scaffold(
              appBar: AppBar(title: Text('Заказ #${order.orderNumber}')),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('ID', order.id.toString()),
                    _infoRow('Номер заказа', order.orderNumber),
                    _infoRow('Клиент', client?.companyName ?? 'ID: ${order.clientId}'),
                    _infoRow('Описание груза', order.cargoDescription),
                    _infoRow('Вес', '${order.weight} кг'),
                    _infoRow('Объём', '${order.volume} м³'),
                    _infoRow('Дата отправки',
                      order.shippingDate.toLocal().toString().split(' ')[0]),
                    if (order.deliveryDate != null)
                      _infoRow('Дата доставки',
                        order.deliveryDate!.toLocal().toString().split(' ')[0]),
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
                      const Text('Нет грузов', style: TextStyle(color: Colors.grey)),

                    const Divider(height: 32),
                    const Text(
                      'Маршруты',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (routeList.isNotEmpty)
                      ...routeList.map((r) => _infoRow('•', r.name))
                    else
                      const Text('Нет маршрутов', style: TextStyle(color: Colors.grey)),

                    if (order.isDeleted)
                      _infoRow('Статус', 'Скрыт', color: Colors.orange),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go('/orders'),
                          child: const Text('Назад'),
                        ),
                        ElevatedButton(
                          onPressed: () => context.go('/orders/${order.id}/edit'),
                          child: const Text('Редактировать'),
                        ),
                        if (!order.isDeleted) ...[
                          ElevatedButton(
                            onPressed: () => _softDelete(context, order.id),
                            child: const Text('Скрыть'),
                          ),
                          ElevatedButton(
                            onPressed: () => _hardDelete(context, order.id),
                            child: const Text('Удалить'),
                          ),
                        ] else ...[
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
            );
          },
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'in_transit': return 'В пути';
      case 'delivered': return 'Доставлено';
      case 'cancelled': return 'Отменено';
      default: return status;
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
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Future<void> _softDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть заказ?'),
        content: const Text('Заказ будет скрыт, но не удалён. Его можно будет восстановить.'),
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
    if (confirmed == true) {
      final repository = Provider.of<PersistentOrderRepository>(context, listen: false);
      await repository.softDelete(id);
      final notifier = Provider.of<OrderListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ скрыт')),
      );
      context.go('/orders');
    }
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final orderRepo = Provider.of<PersistentOrderRepository>(context, listen: false);
    final order = await orderRepo.findById(id);
    if (order == null) return;

    final related = <String>[];

    if (order.clientId > 0) {
      final clientRepo = Provider.of<PersistentClientRepository>(context, listen: false);
      final client = await clientRepo.findById(order.clientId);
      if (client != null) {
        related.add('• Клиент: ${client.companyName}');
      }
    }

    if (order.cargoIds.isNotEmpty) {
      final cargoRepo = Provider.of<PersistentCargoRepository>(context, listen: false);
      for (final cargoId in order.cargoIds) {
        final cargo = await cargoRepo.findById(cargoId);
        if (cargo != null) {
          related.add('• Груз: ${cargo.name}');
        }
      }
    }

    if (order.routeIds.isNotEmpty) {
      final routeRepo = Provider.of<PersistentRouteRepository>(context, listen: false);
      for (final routeId in order.routeIds) {
        final route = await routeRepo.findById(routeId);
        if (route != null) {
          related.add('• Маршрут: ${route.name}');
        }
      }
    }

    if (related.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить заказ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Этот заказ связан со следующими записями:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...related.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(item, style: const TextStyle(fontSize: 14)),
              )),
              const SizedBox(height: 12),
              Text(
                'Количество связанных записей: ${related.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Сначала удалите или переназначьте связанные записи, затем попробуйте снова.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Удалить заказ навсегда?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Это действие нельзя отменить!',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 14)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить навсегда', style: TextStyle(fontSize: 14, color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repository = Provider.of<PersistentOrderRepository>(context, listen: false);
      await repository.hardDelete(id);
      final notifier = Provider.of<OrderListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ удалён навсегда')),
      );
      context.go('/orders');
    }
  }

  Future<void> _restore(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить заказ?'),
        content: const Text('Заказ снова появится в списке.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repository = Provider.of<PersistentOrderRepository>(context, listen: false);
      await repository.restore(id);
      final notifier = Provider.of<OrderListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ восстановлен')),
      );
      context.go('/orders');
    }
  }
}
