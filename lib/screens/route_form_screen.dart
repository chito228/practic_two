import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/reference_cache.dart';
import '../models/route.dart' as model;
import '../models/vehicle.dart';
import '../repositories/route_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../widgets/generic_form.dart';
import '../state/route_list_notifier.dart';

class RouteFormScreen extends StatefulWidget {
  final int? id;
  const RouteFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends State<RouteFormScreen> {
  bool _isLoading = true;
  model.Route? _route;
  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cache = context.read<ReferenceCache>();

    // Справочник vehicles кэшируется.
    _vehicles = await cache.load('vehicles', () {
      final repo = context.read<VehicleRepository>();
      return repo.findAll();
    });

    if (!mounted) return;

    if (widget.isEditing) {
      final routeRepo = context.read<RouteRepository>();
      final r = await routeRepo.findById(widget.id!);
      if (r != null) _route = r;
    } else {
      _route = model.Route(
        id: 0,
        name: '',
        origin: '',
        destination: '',
        distance: 0.0,
        vehicleId: _vehicles.isNotEmpty ? _vehicles.first.id : 0,
        estimatedTime: 0.0,
        status: 'active',
        orderIds: [],
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save(Map<String, dynamic> values) async {
    final repo = context.read<RouteRepository>();
    final cache = context.read<ReferenceCache>();

    final route = model.Route(
      id: _route?.id ?? 0,
      name: (values['name'] as String?) ?? '',
      origin: (values['origin'] as String?) ?? '',
      destination: (values['destination'] as String?) ?? '',
      distance: double.tryParse(values['distance']?.toString() ?? '') ?? 0.0,
      vehicleId: (values['vehicleId'] as int?) ?? 0,
      estimatedTime: double.tryParse(values['estimatedTime']?.toString() ?? '') ?? 0.0,
      status: (values['status'] as String?) ?? 'active',
      orderIds: _route?.orderIds ?? [],
    );

    if (widget.isEditing) {
      await repo.update(route);
    } else {
      await repo.create(route);
    }

    // Сбрасываем кэш справочника маршрутов.
    cache.invalidate('routes');

    if (!mounted) return;
    final notifier = context.read<RouteListNotifier>();
    await notifier.load();

    if (mounted) context.go('/routes');
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
      title: widget.isEditing ? 'Редактирование маршрута' : 'Создание маршрута',
      isEditing: widget.isEditing,
      initialValues: {
        'name': _route?.name ?? '',
        'origin': _route?.origin ?? '',
        'destination': _route?.destination ?? '',
        'distance': _route?.distance.toString() ?? '0',
        'vehicleId': _route?.vehicleId,
        'estimatedTime': _route?.estimatedTime.toString() ?? '0',
        'status': _route?.status ?? 'active',
      },
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Название маршрута',
          maxLength: 150,
        ),
        FormFieldConfig(
          key: 'origin',
          label: 'Откуда',
          maxLength: 100,
        ),
        FormFieldConfig(
          key: 'destination',
          label: 'Куда',
          maxLength: 100,
        ),
        FormFieldConfig(
          key: 'distance',
          label: 'Расстояние (км)',
          type: FormFieldType.double,
        ),
        FormFieldConfig(
          key: 'vehicleId',
          label: 'Транспорт',
          type: FormFieldType.dropdown,
          options: _vehicles.map((v) => DropdownMenuItem(
            value: v.id,
            child: Text('${v.plateNumber} - ${v.driverName}'),
          )).toList(),
        ),
        FormFieldConfig(
          key: 'estimatedTime',
          label: 'Расчётное время (часов)',
          type: FormFieldType.double,
        ),
        FormFieldConfig(
          key: 'status',
          label: 'Статус',
          type: FormFieldType.dropdown,
          options: const [
            DropdownMenuItem(value: 'active', child: Text('Активный')),
            DropdownMenuItem(value: 'completed', child: Text('Завершён')),
            DropdownMenuItem(value: 'cancelled', child: Text('Отменён')),
          ],
        ),
      ],
      onSubmit: _save,
      onCancel: () => context.go('/routes'),
    );
  }
}
