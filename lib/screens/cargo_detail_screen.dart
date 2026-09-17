import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../repositories/cargo_repository.dart';
import '../state/auth_notifier.dart';
import '../state/cargo_list_notifier.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/entity_dependencies.dart';

class CargoDetailScreen extends StatelessWidget {
  final String id;
  const CargoDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<CargoRepository>(context);
    final auth = context.watch<AuthNotifier>();

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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('ID', cargo.id),
                  _infoRow('Название', cargo.name),
                  if (cargo.description != null)
                    _infoRow('Описание', cargo.description!),
                  _infoRow('Вес за единицу', '${cargo.weightPerUnit} кг'),
                  _infoRow('Объём за единицу', '${cargo.volumePerUnit} м³'),
                  if (cargo.isDeleted)
                    _infoRow('Статус', 'Скрыт', color: Colors.orange),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/cargo'),
                        child: const Text('Назад'),
                      ),
                      if (auth.uiCanEditBusiness && !cargo.isDeleted)
                        ElevatedButton(
                          onPressed: () =>
                              context.go('/cargo/${cargo.id}/edit'),
                          child: const Text('Редактировать'),
                        ),
                      if (!cargo.isDeleted) ...[
                        if (auth.uiCanSoftDelete)
                          ElevatedButton(
                            onPressed: () => _softDelete(context, cargo.id),
                            child: const Text('Скрыть'),
                          ),
                        if (auth.uiCanHardDelete)
                          ElevatedButton(
                            onPressed: () => _hardDelete(context, cargo),
                            child: const Text('Удалить'),
                          ),
                      ] else ...[
                        if (auth.uiCanHardDelete)
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
        title: const Text('Скрыть груз?'),
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
    final repository = Provider.of<CargoRepository>(context, listen: false);
    await repository.softDelete(id);
    if (!context.mounted) return;
    final notifier = Provider.of<CargoListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/cargo');
  }

  Future<void> _hardDelete(BuildContext context, dynamic cargo) async {
    final blockers = await EntityDependencies.forCargo(context, cargo.id);

    if (blockers.isNotEmpty) {
      if (!context.mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: cargo.name,
        blockers: blockers,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить груз навсегда?'),
        content: const Text('Это действие нельзя отменить!'),
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
    final repository = Provider.of<CargoRepository>(context, listen: false);
    await repository.hardDelete(cargo.id);
    if (!context.mounted) return;
    final notifier = Provider.of<CargoListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/cargo');
  }

  Future<void> _restore(BuildContext context, String id) async {
    if (!context.mounted) return;
    final repository = Provider.of<CargoRepository>(context, listen: false);
    await repository.restore(id);
    if (!context.mounted) return;
    final notifier = Provider.of<CargoListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;
    context.go('/cargo');
  }
}
