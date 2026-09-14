import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/route_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../repositories/order_repository.dart';
import '../state/route_list_notifier.dart';
import '../models/vehicle.dart';

class RouteDetailScreen extends StatefulWidget {
  final int id;
  const RouteDetailScreen({super.key, required this.id});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  Vehicle? _vehicle;

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<RouteRepository>(context);
    return FutureBuilder(
      future: repository.findById(widget.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Маршрут')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Маршрут')),
            body: const Center(child: Text('Маршрут не найден')),
          );
        }
        final route = snapshot.data!;
        return FutureBuilder(
          future: context.read<VehicleRepository>().findById(route.vehicleId),
          builder: (context, vehicleSnapshot) {
            if (vehicleSnapshot.hasData) {
              _vehicle = vehicleSnapshot.data;
            }
            return Scaffold(
              appBar: AppBar(title: Text(route.name)),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('ID', route.id.toString()),
                    _infoRow('Название', route.name),
                    _infoRow('Откуда', route.origin),
                    _infoRow('Куда', route.destination),
                    _infoRow('Расстояние', '${route.distance} км'),
                    _infoRow('Транспорт',
                      _vehicle != null
                        ? '${_vehicle!.plateNumber} (${_vehicle!.driverName})'
                        : 'ID: ${route.vehicleId}'
                    ),
                    _infoRow('Расчётное время', '${route.estimatedTime} ч'),
                    _infoRow('Статус', _getStatusText(route.status)),
                    _infoRow('Количество заказов', route.orderIds.length.toString()),
                    if (route.isDeleted)
                      _infoRow('Статус', 'Скрыт', color: Colors.orange),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go('/routes'),
                          child: const Text('Назад'),
                        ),
                        ElevatedButton(
                          onPressed: () => context.go('/routes/${route.id}/edit'),
                          child: const Text('Редактировать'),
                        ),
                        if (!route.isDeleted) ...[
                          ElevatedButton(
                            onPressed: () => _softDelete(context, route.id),
                            child: const Text('Скрыть'),
                          ),
                          ElevatedButton(
                            onPressed: () => _hardDelete(context, route.id),
                            child: const Text('Удалить'),
                          ),
                        ] else ...[
                          ElevatedButton(
                            onPressed: () => _restore(context, route.id),
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
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'Активный';
      case 'completed': return 'Завершён';
      case 'cancelled': return 'Отменён';
      default: return status;
    }
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
      final notifier = Provider.of<RouteListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Маршрут скрыт')),
      );
      context.go('/routes');
    }
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);
    final allOrders = await orderRepo.findAll(includeDeleted: true);
    final relatedOrders = allOrders.where((o) => o.routeIds.contains(id) && !o.isDeleted).toList();

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
      final notifier = Provider.of<RouteListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Маршрут удалён навсегда')),
      );
      context.go('/routes');
    }
  }

  Future<void> _restore(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить маршрут?'),
        content: const Text('Маршрут снова появится в списке.'),
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
      final repository = Provider.of<RouteRepository>(context, listen: false);
      await repository.restore(id);
      final notifier = Provider.of<RouteListNotifier>(context, listen: false);
      await notifier.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Маршрут восстановлен')),
      );
      context.go('/routes');
    }
  }
}
