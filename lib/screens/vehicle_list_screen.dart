import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/vehicle_list_notifier.dart';
import '../models/vehicle.dart';
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../utils/debounce.dart';
import '../state/load_status.dart';
import '../repositories/persistent_vehicle_repository.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final Debouncer _debouncer = Debouncer();
  String _searchQuery = '';

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<VehicleListNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Транспорт'),
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
                labelText: 'Поиск по номеру или водителю',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _debouncer.call(() {
                  final repo = context.read<PersistentVehicleRepository>();
                  final items = repo.items.where((v) =>
                      v.plateNumber.toLowerCase().contains(value.toLowerCase()) ||
                      v.driverName.toLowerCase().contains(value.toLowerCase()));
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
        onPressed: () => context.go('/vehicles/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(VehicleListNotifier notifier) {
    final filteredItems = _searchQuery.isEmpty
        ? notifier.items
        : notifier.items.where((v) =>
            v.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            v.driverName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    switch (notifier.status) {
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(child: Text('Ошибка: ${notifier.error}'));
      case LoadStatus.success:
        if (filteredItems.isEmpty) {
          return const Center(child: Text('Нет транспорта'));
        }
        return ResponsiveList<Vehicle>(
          items: filteredItems,
          cardBuilder: (vehicle) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(vehicle.plateNumber),
              subtitle: Text(vehicle.driverName),
              trailing: Text('${vehicle.capacity} т'),
              onTap: () => context.go('/vehicles/${vehicle.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<Vehicle>(
            items: items,
            idOf: (v) => v.id,
            selected: notifier.selected,
            onToggleSelect: notifier.toggleSelection,
            sortField: 'plateNumber',
            sortAscending: true,
            columns: [
              TableColumnSpec<Vehicle>(
                label: 'Номер машины',
                sortField: 'plateNumber',
                build: (v) => Text(v.plateNumber),
              ),
              TableColumnSpec<Vehicle>(
                label: 'Водитель',
                sortField: 'driverName',
                build: (v) => Text(v.driverName),
              ),
              TableColumnSpec<Vehicle>(
                label: 'Грузоподъёмность',
                sortField: 'capacity',
                build: (v) => Text('${v.capacity} т'),
              ),
              TableColumnSpec<Vehicle>(
                label: 'Статус',
                build: (v) => Text(_getStatusText(v.status)),
              ),
              TableColumnSpec<Vehicle>(
                label: 'Удостоверение',
                build: (v) => Text(v.driverLicense != null ? '✓' : '✗'),
              ),
            ],
            actions: (v) => [
              TextButton(
                onPressed: () => context.go('/vehicles/${v.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => context.go('/vehicles/${v.id}/edit'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Ред.', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _softDelete(context, v.id),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  foregroundColor: Colors.orange,
                ),
                child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _hardDelete(context, v.id),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'В работе';
      case 'maintenance': return 'На обслуживании';
      case 'repair': return 'В ремонте';
      default: return status;
    }
  }

  Future<void> _softDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть транспорт?'),
        content: const Text('Транспорт будет скрыт, но не удалён. Его можно будет восстановить.'),
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
      final repository = Provider.of<PersistentVehicleRepository>(context, listen: false);
      await repository.softDelete(id);
      final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить транспорт навсегда?'),
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
      final repository = Provider.of<PersistentVehicleRepository>(context, listen: false);
      await repository.hardDelete(id);
      final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _restore(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить транспорт?'),
        content: const Text('Транспорт снова появится в списке.'),
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
      final repository = Provider.of<PersistentVehicleRepository>(context, listen: false);
      await repository.restore(id);
      final notifier = Provider.of<VehicleListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _confirmDelete(BuildContext context, VehicleListNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить ${notifier.selected.length} единиц транспорта?'),
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
