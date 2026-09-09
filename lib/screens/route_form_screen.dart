import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/route.dart' as model;
import '../models/vehicle.dart';
import '../repositories/persistent_route_repository.dart';
import '../repositories/persistent_vehicle_repository.dart';
import '../validators/validators.dart';
import '../state/route_list_notifier.dart';

class RouteFormScreen extends StatefulWidget {
  final int? id;
  const RouteFormScreen({super.key, this.id});

  bool get isEditing => id != null;
  String get title => isEditing ? 'Редактирование маршрута' : 'Создание маршрута';

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends State<RouteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  model.Route? _route;
  
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  
  int? _vehicleId;
  String _status = 'active';
  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final vehicleRepo = context.read<PersistentVehicleRepository>();
    _vehicles = await vehicleRepo.findAll();

    if (widget.isEditing) {
      final routeRepo = context.read<PersistentRouteRepository>();
      final route = await routeRepo.findById(widget.id!);
      if (route != null) {
        _route = route;
        _nameController.text = route.name;
        _originController.text = route.origin;
        _destinationController.text = route.destination;
        _distanceController.text = route.distance.toString();
        _estimatedTimeController.text = route.estimatedTime.toString();
        _vehicleId = route.vehicleId;
        _status = route.status;
      }
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
      if (_vehicles.isNotEmpty) _vehicleId = _vehicles.first.id;
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_hasUnsavedChanges()) {
          final shouldLeave = await _showUnsavedChangesDialog();
          if (shouldLeave) Navigator.pop(context);
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название маршрута',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final error = Validators.required(v, 'Название маршрута');
                      if (error != null) return error;
                      final repo = context.read<PersistentRouteRepository>();
                      return Validators.unique(
                        v,
                        repo.items,
                        (r) => r.name,
                        widget.id,
                        'Название маршрута',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _originController,
                    decoration: const InputDecoration(
                      labelText: 'Откуда',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.required(v, 'Откуда'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Куда',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.required(v, 'Куда'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _distanceController,
                    decoration: const InputDecoration(
                      labelText: 'Расстояние (км)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.positiveDouble(v, 'Расстояние'),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: _vehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Транспорт',
                      border: OutlineInputBorder(),
                    ),
                    items: _vehicles.map((v) => 
                      DropdownMenuItem(
                        value: v.id, 
                        child: Text('${v.plateNumber} - ${v.driverName}'),
                      )
                    ).toList(),
                    onChanged: (v) => setState(() => _vehicleId = v),
                    validator: (v) => v == null ? 'Выберите транспорт' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _estimatedTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Расчётное время (часов)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.positiveDouble(v, 'Расчётное время'),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Статус',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Активный')),
                      DropdownMenuItem(value: 'completed', child: Text('Завершён')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Отменён')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'active'),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: _save,
                        child: Text(widget.isEditing ? 'Сохранить' : 'Создать'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasUnsavedChanges() {
    if (_route == null) return false;
    return _nameController.text != _route!.name ||
        _originController.text != _route!.origin ||
        _destinationController.text != _route!.destination ||
        _distanceController.text != _route!.distance.toString() ||
        _estimatedTimeController.text != _route!.estimatedTime.toString() ||
        _vehicleId != _route!.vehicleId ||
        _status != _route!.status;
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Несохранённые изменения'),
            content: const Text('У вас есть несохранённые изменения. Вы уверены, что хотите выйти?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Остаться'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Выйти'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите транспорт')),
      );
      return;
    }

    final repo = context.read<PersistentRouteRepository>();
    final route = model.Route(
      id: _route?.id ?? 0,
      name: _nameController.text.trim(),
      origin: _originController.text.trim(),
      destination: _destinationController.text.trim(),
      distance: double.tryParse(_distanceController.text) ?? 0.0,
      vehicleId: _vehicleId!,
      estimatedTime: double.tryParse(_estimatedTimeController.text) ?? 0.0,
      status: _status,
      orderIds: _route?.orderIds ?? [],
    );

    try {
      if (widget.isEditing) {
        await repo.update(route);
      } else {
        await repo.create(route);
      }
      
      final notifier = context.read<RouteListNotifier>();
      await notifier.load();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Маршрут обновлён' : 'Маршрут создан'),
          ),
        );
        Navigator.pop(context);
        context.go('/routes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}
