import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/client_repository.dart';

class ClientDetailScreen extends StatelessWidget {
  final int id;

  const ClientDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<ClientRepository>(context);
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
          appBar: AppBar(
            title: Text(client.name),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('ID', client.id.toString()),
                _infoRow('Компания', client.name),
                _infoRow('Контактное лицо', client.contactPerson),
                _infoRow('Телефон', client.phone),
                _infoRow('Количество заказов', client.orderIds.length.toString()),
                if (client.isDeleted)
                  _infoRow('Статус', 'Удалён', color: Colors.red),
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
