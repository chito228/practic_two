import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/reference_cache.dart';
import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';
import '../widgets/generic_form.dart';
import '../state/vehicle_list_notifier.dart';

class VehicleFormScreen extends StatefulWidget {
  final int? id;
  const VehicleFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  bool _isLoading = true;
  Vehicle? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final repo = context.read<VehicleRepository>();
      final v = await repo.findById(widget.id!);
      if (!mounted) return;
      if (v != null) _vehicle = v;
    } else {
      _vehicle = Vehicle(
        id: 0,
        plateNumber: '',
        driverName: '',
        capacity: 0.0,
        status: 'active',
        routeIds: [],
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save(Map<String, dynamic> values) async {
    final repo = context.read<VehicleRepository>();
    final cache = context.read<ReferenceCache>();

    final vehicle = Vehicle(
      id: _vehicle?.id ?? 0,
      plateNumber: (values['plateNumber'] as String?) ?? '',
      driverName: (values['driverName'] as String?) ?? '',
      capacity: double.tryParse(values['capacity']?.toString() ?? '') ?? 0.0,
      status: (values['status'] as String?) ?? 'active',
      routeIds: _vehicle?.routeIds ?? [],
    );

    if (widget.isEditing) {
      await repo.update(vehicle);
    } else {
      await repo.create(vehicle);
    }

    // Сбрасываем кэш справочника транспорта.
    cache.invalidate('vehicles');

    if (!mounted) return;
    final notifier = context.read<VehicleListNotifier>();
    await notifier.load();

    if (mounted) context.go('/vehicles');
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
      title: widget.isEditing ? 'Редактирование транспорта' : 'Создание транспорта',
      isEditing: widget.isEditing,
      initialValues: {
        'plateNumber': _vehicle?.plateNumber ?? '',
        'driverName': _vehicle?.driverName ?? '',
        'capacity': _vehicle?.capacity.toString() ?? '0',
        'status': _vehicle?.status ?? 'active',
      },
      fields: [
        FormFieldConfig(
          key: 'plateNumber',
          label: 'Номер машины',
          maxLength: 20,
        ),
        FormFieldConfig(
          key: 'driverName',
          label: 'Водитель',
          maxLength: 150,
        ),
        FormFieldConfig(
          key: 'capacity',
          label: 'Грузоподъёмность (тонн)',
          type: FormFieldType.double,
        ),
        FormFieldConfig(
          key: 'status',
          label: 'Статус',
          type: FormFieldType.dropdown,
          options: const [
            DropdownMenuItem(value: 'active', child: Text('В работе')),
            DropdownMenuItem(value: 'maintenance', child: Text('На обслуживании')),
            DropdownMenuItem(value: 'repair', child: Text('В ремонте')),
          ],
        ),
      ],
      onSubmit: _save,
      onCancel: () => context.go('/vehicles'),
    );
  }
}
