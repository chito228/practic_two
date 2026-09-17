import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../repositories/client_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/route_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../widgets/main_scaffold.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  String? _error;

  List<Order> _orders = [];
  List<dynamic> _clients = [];
  List<dynamic> _routes = [];
  List<dynamic> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orderRepo = context.read<OrderRepository>();
      final clientRepo = context.read<ClientRepository>();
      final routeRepo = context.read<RouteRepository>();
      final vehicleRepo = context.read<VehicleRepository>();

      _orders = await orderRepo.findAll();
      _clients = await clientRepo.findAll();
      _routes = await routeRepo.findAll();
      _vehicles = await vehicleRepo.findAll();
    } catch (e) {
      _error = 'Не удалось загрузить статистику: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Статистика',
      currentRoute: '/stats',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _load();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final totalOrders = _orders.length;
    final inTransit = _orders.where((o) => o.status == 'in_transit').length;
    final delivered = _orders.where((o) => o.status == 'delivered').length;
    final cancelled = _orders.where((o) => o.status == 'cancelled').length;

    final totalWeight = _orders.fold<double>(0, (s, o) => s + o.weight);
    final totalVolume = _orders.fold<double>(0, (s, o) => s + o.volume);

    final totalDistance = _routes.fold<double>(
      0,
      (s, r) => s + (r.distance as num).toDouble(),
    );

    final activeVehicles =
        _vehicles.where((v) => v.status == 'active').length;
    final maintenanceVehicles =
        _vehicles.where((v) => v.status == 'maintenance').length;
    final repairVehicles =
        _vehicles.where((v) => v.status == 'repair').length;

    final orderCountByClient = <String, int>{};
    for (final o in _orders) {
      orderCountByClient[o.clientId] =
          (orderCountByClient[o.clientId] ?? 0) + 1;
    }
    final topClients = orderCountByClient.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topClients.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Заказы'),
        _row('Всего заказов', totalOrders.toString()),
        _row('В пути', inTransit.toString()),
        _row('Доставлено', delivered.toString()),
        _row('Отменено', cancelled.toString()),

        _section('Перевозки'),
        _row('Общий вес', '${totalWeight.toStringAsFixed(1)} кг'),
        _row('Общий объём', '${totalVolume.toStringAsFixed(1)} м³'),
        _row(
          'Общее расстояние',
          '${totalDistance.toStringAsFixed(0)} км',
        ),

        _section('Транспорт'),
        _row('Всего единиц', _vehicles.length.toString()),
        _row('В работе', activeVehicles.toString()),
        _row('На обслуживании', maintenanceVehicles.toString()),
        _row('В ремонте', repairVehicles.toString()),

        _section('Топ-5 клиентов по заказам'),
        if (top5.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Нет данных',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...top5.map((entry) {
            final client = _clients.cast<dynamic>().firstWhere(
              (c) => c.id == entry.key,
              orElse: () => null,
            );
            final name = client?.companyName ?? 'Клиент ${entry.key}';
            return _row(name, entry.value.toString());
          }),

        _section('Справочники'),
        _row('Клиентов', _clients.length.toString()),
        _row('Маршрутов', _routes.length.toString()),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
