import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/client.dart';
import '../models/order.dart';
import '../repositories/client_repository.dart';
import '../repositories/order_repository.dart';
import '../state/load_status.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';

/// Диспетчерская — простой список заказов на сегодня.
/// Без стилей, без чипов, без иконок.
class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  List<Order> _orders = [];
  Map<int, String> _clientNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });

    try {
      final orderRepo = context.read<OrderRepository>();
      final clientRepo = context.read<ClientRepository>();

      final results = await Future.wait([
        orderRepo.findAll(),
        clientRepo.findAll(),
      ]);

      if (!mounted) return;

      final allOrders = results[0] as List<Order>;
      final allClients = results[1] as List<Client>;

      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final todayOrders = allOrders
          .where((o) =>
              !o.shippingDate.isBefore(dayStart) &&
              o.shippingDate.isBefore(dayEnd))
          .toList()
        ..sort((a, b) => a.shippingDate.compareTo(b.shippingDate));

      setState(() {
        _orders = todayOrders;
        _clientNames = {for (final c in allClients) c.id: c.companyName};
        _status = LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _status = LoadStatus.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _status = LoadStatus.error;
      });
    }
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    final repo = context.read<OrderRepository>();
    try {
      await repo.update(order.copyWith(status: newStatus));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Диспетчерская')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case LoadStatus.error:
        return ErrorView(message: _error, onRetry: _load);

      case LoadStatus.success:
        if (_orders.isEmpty) {
          return const EmptyView(message: 'На сегодня заказов нет.');
        }
        return ListView.separated(
          itemCount: _orders.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) => _orderTile(_orders[i]),
        );
    }
  }

  Widget _orderTile(Order o) {
    final client = _clientNames[o.clientId] ?? 'Клиент #${o.clientId}';
    final time = _formatTime(o.shippingDate);

    return ListTile(
      onTap: () => context.go('/orders/${o.id}'),
      title: Text('$time  ${o.orderNumber}  $client'),
      subtitle: Text(o.cargoDescription),
      trailing: _actionButton(o),
    );
  }

  Widget _actionButton(Order o) {
    if (o.status == 'in_transit') {
      return TextButton(
        onPressed: () => _updateStatus(o, 'delivered'),
        child: const Text('Доставлено'),
      );
    }
    if (o.status == 'delivered') {
      return const Text('Доставлено');
    }
    if (o.status == 'cancelled') {
      return const Text('Отменено');
    }
    return const SizedBox.shrink();
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
