import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/cargo_list_notifier.dart';
import '../models/cargo.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../utils/debounce.dart';
import '../state/load_status.dart';
import '../repositories/persistent_cargo_repository.dart';

class CargoListScreen extends StatefulWidget {
  const CargoListScreen({super.key});

  @override
  State<CargoListScreen> createState() => _CargoListScreenState();
}

class _CargoListScreenState extends State<CargoListScreen> {
  final Debouncer _debouncer = Debouncer();
  String _searchQuery = '';

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CargoListNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Грузы'),
        actions: [
          if (notifier.hasSelection)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  'Выбрано: ${notifier.selected.length}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          if (notifier.hasSelection)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, notifier),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Поиск по названию',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _debouncer.call(() {
                  final repo = context.read<PersistentCargoRepository>();
                  final items = repo.items.where((c) =>
                      c.name.toLowerCase().contains(value.toLowerCase()) ||
                      (c.description?.toLowerCase().contains(value.toLowerCase()) ?? false));
                  setState(() {});
                });
              },
            ),
          ),
          Expanded(
            child: _buildContent(notifier),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/cargo/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(CargoListNotifier notifier) {
    final filteredItems = _searchQuery.isEmpty
        ? notifier.items
        : notifier.items.where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (c.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
            .toList();

    switch (notifier.status) {
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(child: Text('Ошибка: ${notifier.error}'));
      case LoadStatus.success:
        if (filteredItems.isEmpty) {
          return const Center(child: Text('Нет грузов'));
        }
        return ResponsiveList<Cargo>(
          items: filteredItems,
          cardBuilder: (cargo) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(cargo.name),
              subtitle: Text('Вес: ${cargo.weightPerUnit} кг, Объём: ${cargo.volumePerUnit} м³'),
              trailing: Text('${cargo.orderIds.length} заказов'),
              onTap: () => context.go('/cargo/${cargo.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<Cargo>(
            items: items,
            idOf: (c) => c.id,
            selected: notifier.selected,
            onToggleSelect: notifier.toggleSelection,
            sortField: 'name',
            sortAscending: true,
            columns: [
              TableColumnSpec<Cargo>(
                label: 'Название',
                build: (c) => Text(c.name),
              ),
              TableColumnSpec<Cargo>(
                label: 'Вес (кг)',
                build: (c) => Text(c.weightPerUnit.toString()),
              ),
              TableColumnSpec<Cargo>(
                label: 'Объём (м³)',
                build: (c) => Text(c.volumePerUnit.toString()),
              ),
              TableColumnSpec<Cargo>(
                label: 'Заказов',
                build: (c) => Text(c.orderIds.length.toString()),
              ),
            ],
            actions: (c) => [
              TextButton(
                onPressed: () => context.go('/cargo/${c.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => context.go('/cargo/${c.id}/edit'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Ред.', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _softDelete(context, c.id),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  foregroundColor: Colors.orange,
                ),
                child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _hardDelete(context, c.id),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  foregroundColor: Colors.red,
                ),
                child: const Text('Удалить', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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
    }
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
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
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repository = Provider.of<PersistentCargoRepository>(context, listen: false);
      await repository.hardDelete(id);
      final notifier = Provider.of<CargoListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _confirmDelete(BuildContext context, CargoListNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить ${notifier.selected.length} грузов?'),
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
    if (confirmed == true) {
      await notifier.deleteSelected();
    }
  }
}
