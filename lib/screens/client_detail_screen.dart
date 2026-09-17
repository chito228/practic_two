import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../models/client.dart';
import '../repositories/client_repository.dart';
import '../state/auth_notifier.dart';
import '../state/client_list_notifier.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/entity_dependencies.dart';

class ClientDetailScreen extends StatelessWidget {
  final String id;
  const ClientDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<ClientRepository>(context);
    final auth = context.watch<AuthNotifier>();

    return FutureBuilder<Client?>(
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('ID', client.id),
                  _infoRow('Компания', client.companyName),
                  _infoRow('Контактное лицо', client.contactPerson),
                  _infoRow('Телефон', client.phone),
                  _infoRow('Email', client.email),
                  if (client.address != null) _infoRow('Адрес', client.address!),
                  if (client.isDeleted)
                    _infoRow('Статус', 'Скрыт', color: Colors.orange),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/clients'),
                        child: const Text('Назад'),
                      ),
                      if (auth.uiCanEditBusiness && !client.isDeleted)
                        ElevatedButton(
                          onPressed: () =>
                              context.go('/clients/${client.id}/edit'),
                          child: const Text('Редактировать'),
                        ),
                      if (!client.isDeleted) ...[
                        if (auth.uiCanSoftDelete)
                          ElevatedButton(
                            onPressed: () => _softDelete(context, client.id),
                            child: const Text('Скрыть'),
                          ),
                        if (auth.uiCanHardDelete)
                          ElevatedButton(
                            onPressed: () => _hardDelete(context, client),
                            child: const Text('Удалить'),
                          ),
                      ] else ...[
                        if (auth.uiCanHardDelete)
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

  Future<void> _softDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть клиента?'),
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
    final repository = Provider.of<ClientRepository>(context, listen: false);
    await repository.softDelete(id);
    if (!context.mounted) return;
    final notifier = Provider.of<ClientListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/clients');
  }

  Future<void> _hardDelete(BuildContext context, Client client) async {
    final blockers = await EntityDependencies.forClient(context, client.id);

    if (blockers.isNotEmpty) {
      if (!context.mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: client.companyName,
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
    final repository = Provider.of<ClientRepository>(context, listen: false);
    await repository.hardDelete(client.id);
    if (!context.mounted) return;
    final notifier = Provider.of<ClientListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/clients');
  }

  Future<void> _restore(BuildContext context, String id) async {
    if (!context.mounted) return;
    final repository = Provider.of<ClientRepository>(context, listen: false);
    await repository.restore(id);
    if (!context.mounted) return;
    final notifier = Provider.of<ClientListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/clients');
  }
}
