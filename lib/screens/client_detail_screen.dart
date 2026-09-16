import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../repositories/client_repository.dart';
import '../repositories/order_repository.dart';
import '../state/auth_notifier.dart';
import '../state/client_list_notifier.dart';

class ClientDetailScreen extends StatelessWidget {
  final int id;
  const ClientDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<ClientRepository>(context);
    final auth = context.watch<AuthNotifier>();

    return FutureBuilder(
      future: repository.findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Клиент')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Клиент')),
            body: const Center(child: Text('Клиент не найден')),
          );
        }
        final client = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(client.companyName)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('ID', client.id.toString()),
                _infoRow('Компания', client.companyName),
                _infoRow('Контактное лицо', client.contactPerson),
                _infoRow('Телефон', client.phone),
                _infoRow('Email', client.email),
                if (client.address != null) _infoRow('Адрес', client.address!),
                _infoRow(
                  'Количество заказов',
                  client.orderIds.length.toString(),
                ),
                if (client.isDeleted)
                  _infoRow('Статус', 'Скрыт', color: Colors.orange),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/clients'),
                      child: const Text('Назад'),
                    ),

                    // Редактирование — только logist и выше.
                    if (auth.uiHas(Role.logist))
                      ElevatedButton(
                        onPressed: () =>
                            context.go('/clients/${client.id}/edit'),
                        child: const Text('Редактировать'),
                      ),

                    // Скрыть/удалить — только admin.
                    if (!client.isDeleted) ...[
                      if (auth.uiHas(Role.admin))
                        ElevatedButton(
                          onPressed: () => _softDelete(context, client.id),
                          child: const Text('Скрыть'),
                        ),
                      if (auth.uiHas(Role.admin))
                        ElevatedButton(
                          onPressed: () => _hardDelete(context, client.id),
                          child: const Text('Удалить'),
                        ),
                    ] else ...[
                      if (auth.uiHas(Role.admin))
                        ElevatedButton(
                          onPressed: () => _restore(context, client.id),
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
  }

  Widget _infoRow(String label, String value, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
        title: const Text('Скрыть клиента?'),
        content: const Text(
          'Клиент будет скрыт, но не удалён. Его можно будет восстановить.',
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
      final repository = Provider.of<ClientRepository>(context, listen: false);
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
    final notifier = Provider.of<ClientListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Клиент скрыт')));
    context.go('/clients');
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);
    List<dynamic> orders;
    try {
      orders = await orderRepo.findByClientId(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (!context.mounted) return;

    if (orders.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить клиента',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'У этого клиента есть активные заказы:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '• Заказ #${order.orderNumber} (${order.cargoDescription})',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Количество заказов: ${orders.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
          'Удалить клиента навсегда?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Это действие нельзя отменить!\n\n'
          'Все данные клиента будут безвозвратно удалены.',
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
      final repository = Provider.of<ClientRepository>(context, listen: false);
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
    final notifier = Provider.of<ClientListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Клиент удалён навсегда'),
        backgroundColor: Colors.green,
      ),
    );
    context.go('/clients');
  }

  Future<void> _restore(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить клиента?'),
        content: const Text('Клиент снова появится в списке.'),
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
      final repository = Provider.of<ClientRepository>(context, listen: false);
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
    final notifier = Provider.of<ClientListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Клиент восстановлен')));
    context.go('/clients');
  }
}
