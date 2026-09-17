import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/reference_cache.dart';
import '../models/warehouse.dart';
import '../models/cargo.dart';
import '../models/route.dart' as model;
import '../models/app_user.dart';
import '../repositories/warehouse_repository.dart';
import '../repositories/cargo_repository.dart';
import '../repositories/route_repository.dart';
import '../repositories/user_repository.dart';
import '../widgets/generic_form.dart';
import '../state/warehouse_list_notifier.dart';

class WarehouseFormScreen extends StatefulWidget {
  final int? id;
  const WarehouseFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen> {
  bool _isLoading = true;
  Warehouse? _warehouse;
  List<Cargo> _cargos = [];
  List<model.Route> _routes = [];
  List<AppUser> _managers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cache = context.read<ReferenceCache>();
      final cargoRepo = context.read<CargoRepository>();
      final routeRepo = context.read<RouteRepository>();
      final userRepo = context.read<UserRepository>();

      _cargos = await cache.load('cargo', () => cargoRepo.findAll());
      _routes = await cache.load('routes', () => routeRepo.findAll());
      _managers = await userRepo.findAll();

      if (widget.isEditing) {
        final repo = context.read<WarehouseRepository>();
        final w = await repo.findById(widget.id!);
        if (w != null) _warehouse = w;
      } else {
        _warehouse = const Warehouse(
          id: 0,
          name: '',
          address: '',
          type: WarehouseType.dry,
          capacity: 0.0,
          currentLoad: 0.0,
          cargoIds: [],
          routeIds: [],
        );
      }
    } catch (_) {
      // Игнорируем: показываем форму с пустыми справочниками.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save(Map<String, dynamic> values) async {
    final repo = context.read<WarehouseRepository>();

    final typeValue = values['type'];
    final type = typeValue is WarehouseType
        ? typeValue
        : WarehouseType.fromString(typeValue?.toString());

    final warehouse = Warehouse(
      id: _warehouse?.id ?? 0,
      name: (values['name'] as String?) ?? '',
      address: (values['address'] as String?) ?? '',
      type: type,
      capacity:
          double.tryParse(values['capacity']?.toString() ?? '') ?? 0.0,
      currentLoad:
          double.tryParse(values['currentLoad']?.toString() ?? '') ?? 0.0,
      managerId: values['managerId'] as int?,
      cargoIds: (values['cargoIds'] as List<int>?) ?? [],
      routeIds: (values['routeIds'] as List<int>?) ?? [],
    );

    if (widget.isEditing) {
      await repo.update(warehouse);
    } else {
      await repo.create(warehouse);
    }

    if (!mounted) return;
    final notifier = context.read<WarehouseListNotifier>();
    await notifier.load();
    if (mounted) context.go('/warehouses');
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
      title: widget.isEditing
          ? 'Редактирование склада'
          : 'Создание склада',
      isEditing: widget.isEditing,
      initialValues: {
        'name': _warehouse?.name ?? '',
        'address': _warehouse?.address ?? '',
        'type': _warehouse?.type ?? WarehouseType.dry,
        'capacity': _warehouse?.capacity.toString() ?? '0',
        'currentLoad': _warehouse?.currentLoad.toString() ?? '0',
        'managerId': _warehouse?.managerId,
        'cargoIds': _warehouse?.cargoIds ?? <int>[],
        'routeIds': _warehouse?.routeIds ?? <int>[],
      },
      optionsData: {'cargoIds': _cargos, 'routeIds': _routes},
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Название склада',
          maxLength: 150,
        ),
        FormFieldConfig(
          key: 'address',
          label: 'Адрес',
          maxLength: 300,
        ),
        FormFieldConfig(
          key: 'type',
          label: 'Тип склада',
          type: FormFieldType.dropdown,
          options: WarehouseType.values
              .map(
                (t) => DropdownMenuItem<WarehouseType>(
                  value: t,
                  child: Text(t.label),
                ),
              )
              .toList(),
        ),
        FormFieldConfig(
          key: 'capacity',
          label: 'Вместимость (м³)',
          type: FormFieldType.double,
        ),
        FormFieldConfig(
          key: 'currentLoad',
          label: 'Текущая загрузка (м³)',
          type: FormFieldType.double,
        ),
        FormFieldConfig(
          key: 'managerId',
          label: 'Ответственный',
          type: FormFieldType.dropdown,
          required: false,
          options: _managers
              .map(
                (u) => DropdownMenuItem(
                  value: u.id,
                  child: Text('${u.fullName} (${u.role.label})'),
                ),
              )
              .toList(),
        ),
        FormFieldConfig(
          key: 'cargoIds',
          label: 'Грузы',
          type: FormFieldType.multiSelect,
          required: false,
        ),
        FormFieldConfig(
          key: 'routeIds',
          label: 'Маршруты',
          type: FormFieldType.multiSelect,
          required: false,
        ),
      ],
      onSubmit: _save,
      onCancel: () => context.go('/warehouses'),
    );
  }
}
