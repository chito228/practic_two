import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../repositories/order_repository.dart';
import '../state/auth_notifier.dart';
import '../state/order_list_notifier.dart';

class OrderDetailScreen extends StatelessWidget {
  final int id;
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

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Заказ')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ошибка загрузки: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/orders/$id'),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == null) {
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
                  _infoRow('ID', order.id.toString()),
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

                      // Редактирование — logist и выше.
                      if (auth.uiHas(Role.logist))
                        ElevatedButton(
                          onPressed: () =>
                              context.go('/orders/${order.id}/edit'),
                          child: const Text('Редактировать'),
                        ),

                      // Скрыть — logist и выше.
                      if (!order.isDeleted) ...[
                        if (auth.uiHas(Role.logist))
                          ElevatedButton(
                            onPressed: () => _softDelete(context, order.id),
                            child: const Text('Скрыть'),
                          ),
                        // Удалить навсегда — только admin.
                        if (auth.uiHas(Role.admin))
                          ElevatedButton(
                            onPressed: () => _hardDelete(context, order.id),
                            child: const Text('Удалить'),
                          ),
                      ] else ...[
                        // Восстановление — только admin.
                        if (auth.uiHas(Role.admin))
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

  Future<void> _softDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть заказ?'),
        content: const Text(
          'Заказ будет скрыт, но не удалён. Его можно будет восстановить.',
        ),
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

    try {
      final repository = Provider.of<OrderRepository>(context, listen: false);
      await repository.softDelete(id);
    } on ForbiddenException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ConflictException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<OrderListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Заказ скрыт')));
    context.go('/orders');
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);

    OrderFull? full;
    try {
      full = await orderRepo.findByIdWithRelations(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (full == null || !context.mounted) return;

    final related = <String>[];

    if (full.client != null) {
      related.add('• Клиент: ${full.client!.companyName}');
    }
    for (final c in full.cargo) {
      related.add('• Груз: ${c.name}');
    }
    for (final r in full.routes) {
      related.add('• Маршрут: ${r.name}');
    }
    if (!context.mounted) return;

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
              ...related.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Количество связанных записей: ${related.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
            child: const Text(
              'Удалить навсегда',
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final repository = Provider.of<OrderRepository>(context, listen: false);
      await repository.hardDelete(id);
    } on ForbiddenException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ConflictException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<OrderListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Заказ удалён навсегда')));
    context.go('/orders');
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
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final repository = Provider.of<OrderRepository>(context, listen: false);
      await repository.restore(id);
    } on ForbiddenException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    } on ConflictException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<OrderListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Заказ восстановлен')));
    context.go('/orders');
  }
}
