import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/route_list_notifier.dart';
import '../models/route.dart' as model;
import '../widgets/entity_table.dart';
import '../widgets/responsive_list.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../utils/debounce.dart';
import '../state/load_status.dart';
import '../repositories/route_repository.dart';
import '../repositories/order_repository.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  final Debouncer _debouncer = Debouncer();
  String _searchQuery = '';

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<RouteListNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Маршруты'),
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
        onPressed: () => context.go('/routes/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(RouteListNotifier notifier) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case LoadStatus.error:
        return ErrorView(
          message: notifier.error,
          onRetry: () => notifier.load(),
        );

      case LoadStatus.success:
        final filteredItems = _searchQuery.isEmpty
            ? notifier.items
            : notifier.items
                .where((r) =>
                    r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.origin.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.destination.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

        if (filteredItems.isEmpty) {
          return const EmptyView(message: 'Нет маршрутов');
        }
        return ResponsiveList<model.Route>(
          items: filteredItems,
          cardBuilder: (route) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(route.name),
              subtitle: Text('${route.origin} → ${route.destination}'),
              trailing: Text('${route.distance} км'),
              onTap: () => context.go('/routes/${route.id}'),
            ),
          ),
          tableBuilder: (items) => EntityTable<model.Route>(
            items: items,
            idOf: (r) => r.id,
            selected: notifier.selected,
            onToggleSelect: notifier.toggleSelection,
            sortField: 'name',
            sortAscending: true,
            columns: [
              TableColumnSpec<model.Route>(
                label: 'Название',
                sortField: 'name',
                build: (r) => Text(r.name),
              ),
              TableColumnSpec<model.Route>(
                label: 'Откуда',
                build: (r) => Text(r.origin),
              ),
              TableColumnSpec<model.Route>(
                label: 'Куда',
                build: (r) => Text(r.destination),
              ),
              TableColumnSpec<model.Route>(
                label: 'Расстояние',
                sortField: 'distance',
                build: (r) => Text('${r.distance} км'),
              ),
              TableColumnSpec<model.Route>(
                label: 'Статус',
                build: (r) => Text(_getStatusText(r.status)),
              ),
            ],
            actions: (r) => [
              TextButton(
                onPressed: () => context.go('/routes/${r.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Показать', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => context.go('/routes/${r.id}/edit'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Ред.', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _softDelete(context, r.id),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  foregroundColor: Colors.orange,
                ),
                child: const Text('Скрыть', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _hardDelete(context, r.id),
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
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'Активный';
      case 'completed': return 'Завершён';
      case 'cancelled': return 'Отменён';
      default: return status;
    }
  }

  Future<void> _softDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть маршрут?'),
        content: const Text('Маршрут будет скрыт, но не удалён. Его можно будет восстановить.'),
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
      final repository = Provider.of<RouteRepository>(context, listen: false);
      await repository.softDelete(id);
      if (!context.mounted) return;
      final notifier = Provider.of<RouteListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);
    final allOrders = await orderRepo.findAll(includeDeleted: true);
    final relatedOrders = allOrders.where((o) => o.routeIds.contains(id) && !o.isDeleted).toList();
    if (!context.mounted) return;

    if (relatedOrders.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить маршрут',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Этот маршрут используется в заказах:',
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
          'Удалить маршрут навсегда?',
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
      final repository = Provider.of<RouteRepository>(context, listen: false);
      await repository.hardDelete(id);
      if (!context.mounted) return;
      final notifier = Provider.of<RouteListNotifier>(context, listen: false);
      await notifier.load();
    }
  }

  Future<void> _confirmDelete(BuildContext context, RouteListNotifier notifier) async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);
    final allOrders = await orderRepo.findAll(includeDeleted: true);
    final routesWithOrders = <int>[];

    for (final id in notifier.selected) {
      final relatedOrders = allOrders.where((o) => o.routeIds.contains(id) && !o.isDeleted);
      if (relatedOrders.isNotEmpty) {
        routesWithOrders.add(id);
      }
    }
    if (!context.mounted) return;

    if (routesWithOrders.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Невозможно удалить маршруты',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${routesWithOrders.length} маршрут(ов) используются в заказах.\n\n'
            'Сначала удалите или переназначьте заказы, затем попробуйте снова.',
            style: const TextStyle(fontSize: 14),
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
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить ${notifier.selected.length} маршрутов?'),
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
