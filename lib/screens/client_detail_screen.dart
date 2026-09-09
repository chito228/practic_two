import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/persistent_client_repository.dart';
import '../repositories/persistent_order_repository.dart';
import '../state/client_list_notifier.dart';
import '../models/client.dart';

class ClientDetailScreen extends StatelessWidget {
  final int id;
  const ClientDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<PersistentClientRepository>(context);
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
                _infoRow('Количество заказов', client.orderIds.length.toString()),
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
                    ElevatedButton(
                      onPressed: () => context.go('/clients/${client.id}/edit'),
                      child: const Text('Редактировать'),
                    ),
                    if (!client.isDeleted) ...[
                      ElevatedButton(
                        onPressed: () => _softDelete(context, client.id),
                        child: const Text('Скрыть'),
                      ),
                      ElevatedButton(
                        onPressed: () => _hardDelete(context, client.id),
                        child: const Text('Удалить'),
                      ),
                    ] else ...[
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
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
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
        content: const Text('Клиент будет скрыт, но не удалён. Его можно будет восстановить.'),
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
      final repository = Provider.of<PersistentClientRepository>(context, listen: false);
      await repository.softDelete(id);
      final notifier = Provider.of<ClientListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Клиент скрыт')),
      );
      context.go('/clients');
    }
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    // 1. Проверяем, есть ли у клиента заказы
    final orderRepo = Provider.of<PersistentOrderRepository>(context, listen: false);
    final orders = await orderRepo.findByClientId(id);
    
    // 2. Если есть заказы → показываем диалог с запретом
    if (orders.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить клиента',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
              ...orders.map((order) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '• Заказ #${order.orderNumber} (${order.cargoDescription})',
                  style: const TextStyle(fontSize: 14),
                ),
              )),
              const SizedBox(height: 12),
              Text(
                'Количество заказов: ${orders.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Сначала удалите или переназначьте заказы, затем попробуйте снова.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 3. Если заказов нет → спрашиваем подтверждение
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Удалить клиента навсегда?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Это действие нельзя отменить!\n\n'
          'Все данные клиента будут безвозвратно удалены.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Отмена',
              style: TextStyle(fontSize: 14),
            ),
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
    
    // 4. Если подтвердил → удаляем
    if (confirmed == true) {
      final repository = Provider.of<PersistentClientRepository>(context, listen: false);
      await repository.hardDelete(id);
      final notifier = Provider.of<ClientListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Клиент удалён навсегда')),
      );
      context.go('/clients');
    }
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
    if (confirmed == true) {
      final repository = Provider.of<PersistentClientRepository>(context, listen: false);
      await repository.restore(id);
      final notifier = Provider.of<ClientListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Клиент восстановлен')),
      );
      context.go('/clients');
    }
  }
}
