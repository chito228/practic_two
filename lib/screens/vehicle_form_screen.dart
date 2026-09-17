import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../core/reference_cache.dart';
import '../models/vehicle.dart';
import '../models/driver_license.dart';
import '../repositories/vehicle_repository.dart';
import '../repositories/driver_license_repository.dart';
import '../state/vehicle_list_notifier.dart';

class VehicleFormScreen extends StatefulWidget {
  final String? id;
  const VehicleFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ─── Контроллеры полей транспорта ────────────────────
  final _plateController = TextEditingController();
  final _driverController = TextEditingController();
  final _capacityController = TextEditingController();

  // ─── Контроллеры полей удостоверения ─────────────────
  final _licenseNumberController = TextEditingController();
  final _licenseIssuedController = TextEditingController();
  final _licenseExpiresController = TextEditingController();

  String _status = 'active';

  // ─── Чекбокс «Есть удостоверение» ─────────────────────
  bool _hasLicense = false;
  String _licenseCategory = 'B';
  DateTime? _licenseIssuedAt;
  DateTime? _licenseExpiresAt;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Текущий транспорт (при редактировании).
  Vehicle? _vehicle;

  // Существующее удостоверение (при редактировании).
  // null = у машины нет активного удостоверения.
  DriverLicense? _existingLicense;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _driverController.dispose();
    _capacityController.dispose();
    _licenseNumberController.dispose();
    _licenseIssuedController.dispose();
    _licenseExpiresController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final vehicleRepo = context.read<VehicleRepository>();
      final licenseRepo = context.read<DriverLicenseRepository>();

      final v = await vehicleRepo.findById(widget.id!);
      if (!mounted) return;

      if (v != null) {
        _vehicle = v;
        _plateController.text = v.plateNumber;
        _driverController.text = v.driverName;
        _capacityController.text = v.capacity.toString();
        _status = v.status;

        // Пытаемся найти активное удостоверение у этой машины.
        final lic = await licenseRepo.findByVehicleId(v.id);
        if (!mounted) return;

        if (lic != null) {
          _existingLicense = lic;
          _hasLicense = true;
          _licenseNumberController.text = lic.number;
          _licenseCategory = lic.category;
          _licenseIssuedAt = lic.issuedAt;
          _licenseExpiresAt = lic.expiresAt;
          _licenseIssuedController.text = _formatDate(lic.issuedAt);
          _licenseExpiresController.text = _formatDate(lic.expiresAt);
        } else {
          // Удостоверения нет — чекбокс снят.
          _hasLicense = false;
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate({required bool isIssued}) async {
    final initial = isIssued
        ? (_licenseIssuedAt ?? DateTime.now())
        : (_licenseExpiresAt ??
            DateTime.now().add(const Duration(days: 365 * 5)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isIssued) {
        _licenseIssuedAt = picked;
        _licenseIssuedController.text = _formatDate(picked);
      } else {
        _licenseExpiresAt = picked;
        _licenseExpiresController.text = _formatDate(picked);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final vehicleRepo = context.read<VehicleRepository>();
      final licenseRepo = context.read<DriverLicenseRepository>();
      final cache = context.read<ReferenceCache>();

      // ─── 1. Транспорт ─────────────────────────────────
      final vehicle = Vehicle(
        id: _vehicle?.id ?? '',
        plateNumber: _plateController.text.trim(),
        driverName: _driverController.text.trim(),
        capacity: double.tryParse(_capacityController.text.trim()) ?? 0.0,
        status: _status,
        isDeleted: _vehicle?.isDeleted ?? false,
      );

      final savedVehicle = widget.isEditing
          ? await vehicleRepo.update(vehicle)
          : await vehicleRepo.create(vehicle);

      // ─── 2. Удостоверение ─────────────────────────────
      if (_hasLicense) {
        // Галочка стоит → создать или обновить удостоверение.
        final license = DriverLicense(
          id: _existingLicense?.id ?? '',
          number: _licenseNumberController.text.trim(),
          issuedAt: _licenseIssuedAt ?? DateTime.now(),
          expiresAt: _licenseExpiresAt ?? DateTime.now(),
          category: _licenseCategory,
          vehicleId: savedVehicle.id,
          isDeleted: false,
        );

        if (_existingLicense != null) {
          // Было — обновляем.
          await licenseRepo.update(license);
        } else {
          // Не было — создаём.
          await licenseRepo.create(license);
        }
      } else {
        // Галочка снята → если удостоверение было, soft-delete.
        if (_existingLicense != null) {
          await licenseRepo.softDelete(_existingLicense!.id);
          _existingLicense = null;
        }
      }

      cache.invalidate('vehicles');

      if (!mounted) return;
      final notifier = context.read<VehicleListNotifier>();
      await notifier.load();
      if (mounted) context.go('/vehicles');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Редактирование транспорта'
              : 'Создание транспорта',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
          onPressed: () => context.go('/vehicles'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ─── Транспорт ──────────────────────────
                    TextFormField(
                      controller: _plateController,
                      decoration: const InputDecoration(
                        labelText: 'Номер машины',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      maxLength: 20,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Номер машины обязателен'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _driverController,
                      decoration: const InputDecoration(
                        labelText: 'Водитель (ФИО)',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      maxLength: 150,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Водитель обязателен'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Грузоподъёмность (тонн)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Грузоподъёмность обязательна';
                        }
                        final num = double.tryParse(v.trim());
                        if (num == null || num <= 0) {
                          return 'Введите положительное число';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Статус',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('В работе'),
                        ),
                        DropdownMenuItem(
                          value: 'maintenance',
                          child: Text('На обслуживании'),
                        ),
                        DropdownMenuItem(
                          value: 'repair',
                          child: Text('В ремонте'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),

                    // ─── Чекбокс удостоверения ──────────────
                    CheckboxListTile(
                      value: _hasLicense,
                      onChanged: (v) {
                        setState(() {
                          _hasLicense = v ?? false;
                          if (!_hasLicense) {
                            // Очищаем поля, чтобы при повторном
                            // включении начать с чистого листа.
                            _licenseNumberController.clear();
                            _licenseIssuedController.clear();
                            _licenseExpiresController.clear();
                            _licenseIssuedAt = null;
                            _licenseExpiresAt = null;
                            _licenseCategory = 'B';
                          }
                        });
                      },
                      title: const Text('Водительское удостоверение'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // ─── Поля удостоверения (только если галочка) ───
                    if (_hasLicense) ...[
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Номер удостоверения',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                        maxLength: 20,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Номер удостоверения обязателен'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _licenseIssuedController,
                        decoration: InputDecoration(
                          labelText: 'Дата выдачи',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _pickDate(isIssued: true),
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _pickDate(isIssued: true),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Дата выдачи обязательна'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _licenseExpiresController,
                        decoration: InputDecoration(
                          labelText: 'Действительно до',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _pickDate(isIssued: false),
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _pickDate(isIssued: false),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Дата окончания обязательна';
                          }
                          if (_licenseIssuedAt != null &&
                              _licenseExpiresAt != null &&
                              !_licenseExpiresAt!.isAfter(_licenseIssuedAt!)) {
                            return 'Дата окончания должна быть позже выдачи';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _licenseCategory,
                        decoration: const InputDecoration(
                          labelText: 'Категория',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'A', child: Text('A')),
                          DropdownMenuItem(value: 'B', child: Text('B')),
                          DropdownMenuItem(value: 'C', child: Text('C')),
                          DropdownMenuItem(value: 'D', child: Text('D')),
                          DropdownMenuItem(value: 'E', child: Text('E')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _licenseCategory = v);
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed:
                              _isSaving ? null : () => context.go('/vehicles'),
                          child: const Text('Отмена'),
                        ),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.isEditing ? 'Сохранить' : 'Создать',
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
