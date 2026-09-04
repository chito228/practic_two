import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/order_repository.dart';

class OrderDetailScreen extends StatelessWidget {
  final int id;

  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<OrderRepository>(context);
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
        return Scaffold(
          appBar: AppBar(
            title: Text('Заказ #${order.id}'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('ID', order.id.toString()),
                _infoRow('Клиент', order.clientId.toString()),
                _infoRow('Груз', order.cargoDescription),
                _infoRow('Вес (кг)', order.weight.toString()),
                _infoRow('Объём (м³)', order.volume.toString()),
                _infoRow('Дата отправки', order.sendDate.toLocal().toString().split(' ')[0]),
                if (order.deliveryDate != null)
                  _infoRow('Дата доставки', order.deliveryDate!.toLocal().toString().split(' ')[0]),
                _infoRow('Статус', order.status),
                if (order.isDeleted)
                  _infoRow('Статус', 'Удалён', color: Colors.red),
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
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
