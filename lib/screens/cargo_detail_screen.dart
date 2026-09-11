import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/persistent_cargo_repository.dart';
import '../repositories/persistent_order_repository.dart';
import '../state/cargo_list_notifier.dart';
import '../models/cargo.dart';

class CargoDetailScreen extends StatelessWidget {
  final int id;
  const CargoDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<PersistentCargoRepository>(context);
    return FutureBuilder(
      future: repository.findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Груз')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Груз')),
            body: const Center(child: Text('Груз не найден')),
          );
        }
        final cargo = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(cargo.name)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('ID', cargo.id.toString()),
                _infoRow('Название', cargo.name),
                if (cargo.description != null) _infoRow('Описание', cargo.description!),
                _infoRow('Вес за единицу', '${cargo.weightPerUnit} кг'),
                _infoRow('Объём за единицу', '${cargo.volumePerUnit} м³'),
                _infoRow('Количество заказов', cargo.orderIds.length.toString()),
                if (cargo.isDeleted)
                  _infoRow('Статус', 'Скрыт', color: Colors.orange),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/cargo'),
                      child: const Text('Назад'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.go('/cargo/${cargo.id}/edit'),
                      child: const Text('Редактировать'),
                    ),
                    if (!cargo.isDeleted) ...[
                      ElevatedButton(
                        onPressed: () => _softDelete(context, cargo.id),
                        child: const Text('Скрыть'),
                      ),
                      ElevatedButton(
                        onPressed: () => _hardDelete(context, cargo.id),
                        child: const Text('Удалить'),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () => _restore(context, cargo.id),
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
        title: const Text('Скрыть груз?'),
        content: const Text('Груз будет скрыт, но не удалён. Его можно будет восстановить.'),
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
      final repository = Provider.of<PersistentCargoRepository>(context, listen: false);
      await repository.softDelete(id);
      final notifier = Provider.of<CargoListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Груз скрыт')),
      );
      context.go('/cargo');
    }
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final orderRepo = Provider.of<PersistentOrderRepository>(context, listen: false);
    final allOrders = await orderRepo.findAllWithDeleted();
    final relatedOrders = allOrders.where((o) => o.cargoIds.contains(id) && !o.isDeleted).toList();

    if (relatedOrders.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить груз',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Этот груз используется в заказах:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...relatedOrders.map((order) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '• Заказ #${order.orderNumber} (${order.cargoDescription})',
                  style: const TextStyle(fontSize: 14),
                ),
              )),
              const SizedBox(height: 12),
              Text(
                'Количество заказов: ${relatedOrders.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
          'Удалить груз навсегда?',
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
      final repository = Provider.of<PersistentCargoRepository>(context, listen: false);
      await repository.hardDelete(id);
      final notifier = Provider.of<CargoListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Груз удалён навсегда')),
      );
      context.go('/cargo');
    }
  }

  Future<void> _restore(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить груз?'),
        content: const Text('Груз снова появится в списке.'),
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
      final repository = Provider.of<PersistentCargoRepository>(context, listen: false);
      await repository.restore(id);
      final notifier = Provider.of<CargoListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Груз восстановлен')),
      );
      context.go('/cargo');
    }
  }
}
