import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/vehicle.dart';
import '../repositories/persistent_vehicle_repository.dart';
import '../validators/validators.dart';
import '../state/vehicle_list_notifier.dart';

class VehicleFormScreen extends StatefulWidget {
  final int? id;
  const VehicleFormScreen({super.key, this.id});

  bool get isEditing => id != null;
  String get title => isEditing ? 'Редактирование транспорта' : 'Создание транспорта';

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Vehicle? _vehicle;
  
  // Основные поля
  final _plateNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _capacityController = TextEditingController();
  String _status = 'active';
  
  // Водительское удостоверение (один-к-одному)
  final _licenseNumberController = TextEditingController();
  DateTime? _licenseIssuedAt;
  DateTime? _licenseExpiresAt;
  bool _hasLicense = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _driverNameController.dispose();
    _capacityController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final repo = context.read<PersistentVehicleRepository>();
      final vehicle = await repo.findById(widget.id!);
      if (vehicle != null) {
        _vehicle = vehicle;
        _plateNumberController.text = vehicle.plateNumber;
        _driverNameController.text = vehicle.driverName;
        _capacityController.text = vehicle.capacity.toString();
        _status = vehicle.status;
        
        if (vehicle.driverLicense != null) {
          _hasLicense = true;
          _licenseNumberController.text = vehicle.driverLicense!.number;
          _licenseIssuedAt = vehicle.driverLicense!.issuedAt;
          _licenseExpiresAt = vehicle.driverLicense!.expiresAt;
        }
      }
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
                  // Номер машины (уникальный)
                  TextFormField(
                    controller: _plateNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Номер машины',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final error = Validators.required(v, 'Номер машины');
                      if (error != null) return error;
                      final repo = context.read<PersistentVehicleRepository>();
                      return Validators.unique(
                        v,
                        repo.items,
                        (v) => v.plateNumber,
                        widget.id,
                        'Номер машины',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Водитель
                  TextFormField(
                    controller: _driverNameController,
                    decoration: const InputDecoration(
                      labelText: 'Водитель',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.required(v, 'Водитель'),
                  ),
                  const SizedBox(height: 16),

                  // Грузоподъёмность
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Грузоподъёмность (тонн)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.positiveDouble(v, 'Грузоподъёмность'),
                  ),
                  const SizedBox(height: 16),

                  // Статус
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Статус',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('В работе')),
                      DropdownMenuItem(value: 'maintenance', child: Text('На обслуживании')),
                      DropdownMenuItem(value: 'repair', child: Text('В ремонте')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'active'),
                  ),
                  const SizedBox(height: 24),

                  // Раздел: Водительское удостоверение (один-к-одному)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Водительское удостоверение',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _hasLicense,
                                onChanged: (v) => setState(() => _hasLicense = v),
                              ),
                              const Text('Есть'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_hasLicense) ...[
                            TextFormField(
                              controller: _licenseNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Номер удостоверения',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => _hasLicense 
                                  ? Validators.required(v, 'Номер удостоверения')
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _buildDatePickerField(
                              label: 'Дата выдачи',
                              value: _licenseIssuedAt,
                              onChanged: (date) => setState(() => _licenseIssuedAt = date),
                            ),
                            const SizedBox(height: 12),
                            _buildDatePickerField(
                              label: 'Дата истечения',
                              value: _licenseExpiresAt,
                              onChanged: (date) => setState(() => _licenseExpiresAt = date),
                            ),
                          ],
                        ],
                      ),
                    ),
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

  Widget _buildDatePickerField({
    required String label,
    required DateTime? value,
    required void Function(DateTime) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2030),
        );
        if (date != null) onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null 
              ? value.toLocal().toString().split(' ')[0]
              : 'Выберите дату',
        ),
      ),
    );
  }

  bool _hasUnsavedChanges() {
    if (_vehicle == null) return false;
    return _plateNumberController.text != _vehicle!.plateNumber ||
        _driverNameController.text != _vehicle!.driverName ||
        _capacityController.text != _vehicle!.capacity.toString() ||
        _status != _vehicle!.status ||
        _hasLicense != (_vehicle!.driverLicense != null) ||
        (_hasLicense && _licenseNumberController.text != (_vehicle!.driverLicense?.number ?? ''));
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

    if (_hasLicense) {
      if (_licenseIssuedAt == null || _licenseExpiresAt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заполните все поля водительского удостоверения')),
        );
        return;
      }
      if (_licenseExpiresAt!.isBefore(_licenseIssuedAt!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Дата истечения не может быть раньше даты выдачи')),
        );
        return;
      }
    }

    final repo = context.read<PersistentVehicleRepository>();
    
    final vehicle = Vehicle(
      id: _vehicle?.id ?? 0,
      plateNumber: _plateNumberController.text.trim(),
      driverName: _driverNameController.text.trim(),
      capacity: double.tryParse(_capacityController.text) ?? 0.0,
      status: _status,
      driverLicense: _hasLicense ? DriverLicense(
        id: _vehicle?.driverLicense?.id ?? 0,
        number: _licenseNumberController.text.trim(),
        issuedAt: _licenseIssuedAt!,
        expiresAt: _licenseExpiresAt!,
        vehicleId: _vehicle?.id ?? 0,
      ) : null,
      routeIds: _vehicle?.routeIds ?? [],
    );

    try {
      if (widget.isEditing) {
        await repo.update(vehicle);
      } else {
        await repo.create(vehicle);
      }
      
      final notifier = context.read<VehicleListNotifier>();
      await notifier.load();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Транспорт обновлён' : 'Транспорт создан'),
          ),
        );
        Navigator.pop(context);
        context.go('/vehicles');
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
