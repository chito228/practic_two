import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/reference_cache.dart';
import '../models/order.dart';
import '../models/client.dart';
import '../models/cargo.dart';
import '../models/route.dart' as model;
import '../repositories/order_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/cargo_repository.dart';
import '../repositories/route_repository.dart';
import '../widgets/generic_form.dart';
import '../state/order_list_notifier.dart';

class OrderFormScreen extends StatefulWidget {
  final String? id;
  const OrderFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  bool _isLoading = true;
  Order? _order;
  List<Client> _clients = [];
  List<Cargo> _cargoList = [];
  List<model.Route> _routeList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cache = context.read<ReferenceCache>();
      final clientRepo = context.read<ClientRepository>();
      final cargoRepo = context.read<CargoRepository>();
      final routeRepo = context.read<RouteRepository>();

      _clients = await cache.load('clients', () => clientRepo.findAll());
      _cargoList = await cache.load('cargo', () => cargoRepo.findAll());
      _routeList = await cache.load('routes', () => routeRepo.findAll());

      if (!mounted) return;

      if (widget.isEditing) {
        final orderRepo = context.read<OrderRepository>();
        final o = await orderRepo.findById(widget.id!);
        if (o != null) _order = o;
      } else {
        _order = Order(
          id: '',
          orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
          clientId: _clients.isNotEmpty ? _clients.first.id : '',
          cargoIds: const [],
          routeIds: const [],
          cargoDescription: '',
          weight: 0.0,
          volume: 0.0,
          shippingDate: DateTime.now(),
          status: 'in_transit',
        );
      }
    } catch (e) {
      debugPrint('Ошибка загрузки справочников: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save(Map<String, dynamic> values) async {
    final repo = context.read<OrderRepository>();

    final order = Order(
      id: _order?.id ?? '',
      orderNumber: (values['orderNumber'] as String?) ?? '',
      clientId: (values['clientId'] as String?) ?? '',
      cargoIds: (values['cargoIds'] as List<String>?) ?? const [],
      routeIds: (values['routeIds'] as List<String>?) ?? const [],
      cargoDescription: (values['cargoDescription'] as String?) ?? '',
      weight: double.tryParse(values['weight']?.toString() ?? '') ?? 0.0,
      volume: double.tryParse(values['volume']?.toString() ?? '') ?? 0.0,
      shippingDate: (values['shippingDate'] as DateTime?) ?? DateTime.now(),
      deliveryDate: values['deliveryDate'] as DateTime?,
      status: (values['status'] as String?) ?? 'in_transit',
      isDeleted: _order?.isDeleted ?? false,
    );

    if (widget.isEditing) {
      await repo.update(order);
    } else {
      await repo.create(order);
    }

    if (!mounted) return;
    final notifier = context.read<OrderListNotifier>();
    await notifier.load();
    if (mounted) context.go('/orders');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Редактирование' : 'Создание'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GenericForm(
      title: widget.isEditing ? 'Редактирование заказа' : 'Создание заказа',
      isEditing: widget.isEditing,
      initialValues: {
        'orderNumber': _order?.orderNumber ?? '',
        'clientId': _order?.clientId,
        'cargoIds': _order?.cargoIds ?? <String>[],
        'routeIds': _order?.routeIds ?? <String>[],
        'cargoDescription': _order?.cargoDescription ?? '',
        'weight': _order?.weight.toString() ?? '0',
        'volume': _order?.volume.toString() ?? '0',
        'shippingDate': _order?.shippingDate ?? DateTime.now(),
        'deliveryDate': _order?.deliveryDate,
        'status': _order?.status ?? 'in_transit',
      },
      optionsData: {
        'cargoIds': _cargoList,
        'routeIds': _routeList,
      },
      fields: [
        FormFieldConfig(
          key: 'orderNumber',
          label: 'Номер заказа',
          maxLength: 50,
        ),
        FormFieldConfig(
          key: 'clientId',
          label: 'Клиент',
          type: FormFieldType.dropdown,
          options: _clients
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.companyName),
                ),
              )
              .toList(),
        ),
        FormFieldConfig(
          key: 'cargoIds',
          label: 'Грузы',
          type: FormFieldType.multiSelect,
        ),
        FormFieldConfig(
          key: 'routeIds',
          label: 'Маршруты',
          type: FormFieldType.multiSelect,
        ),
        FormFieldConfig(
          key: 'cargoDescription',
          label: 'Описание груза',
          maxLines: 2,
          maxLength: 500,
        ),
        FormFieldConfig(
          key: 'weight',
          label: 'Вес (кг)',
          type: FormFieldType.double,
        ),
        FormFieldConfig(
          key: 'volume',
          label: 'Объём (м³)',
          type: FormFieldType.double,
        ),
        FormFieldConfig(
          key: 'shippingDate',
          label: 'Дата отправки',
          type: FormFieldType.date,
        ),
        FormFieldConfig(
          key: 'deliveryDate',
          label: 'Дата доставки (опционально)',
          type: FormFieldType.date,
          required: false,
        ),
        FormFieldConfig(
          key: 'status',
          label: 'Статус',
          type: FormFieldType.dropdown,
          options: const [
            DropdownMenuItem(value: 'in_transit', child: Text('В пути')),
            DropdownMenuItem(value: 'delivered', child: Text('Доставлено')),
            DropdownMenuItem(value: 'cancelled', child: Text('Отменено')),
          ],
        ),
      ],
      onSubmit: _save,
      onCancel: () => context.go('/orders'),
    );
  }
}
