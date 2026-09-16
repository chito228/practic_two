import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/reference_cache.dart';
import '../models/cargo.dart';
import '../repositories/cargo_repository.dart';
import '../widgets/generic_form.dart';
import '../state/cargo_list_notifier.dart';

class CargoFormScreen extends StatefulWidget {
  final int? id;
  const CargoFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<CargoFormScreen> createState() => _CargoFormScreenState();
}

class _CargoFormScreenState extends State<CargoFormScreen> {
  bool _isLoading = true;
  Cargo? _cargo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final repo = context.read<CargoRepository>();
      final c = await repo.findById(widget.id!);
      if (!mounted) return;
      if (c != null) _cargo = c;
    } else {
      _cargo = Cargo(
        id: 0,
        name: '',
        description: '',
        weightPerUnit: 0.0,
        volumePerUnit: 0.0,
        orderIds: [],
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save(Map<String, dynamic> values) async {
    final repo = context.read<CargoRepository>();
    final cache = context.read<ReferenceCache>();
    final desc = (values['description'] as String?)?.trim() ?? '';

    final cargo = Cargo(
      id: _cargo?.id ?? 0,
      name: (values['name'] as String?) ?? '',
      description: desc.isEmpty ? null : desc,
      weightPerUnit:
          double.tryParse(values['weightPerUnit']?.toString() ?? '') ?? 0.0,
      volumePerUnit:
          double.tryParse(values['volumePerUnit']?.toString() ?? '') ?? 0.0,
      orderIds: _cargo?.orderIds ?? [],
    );

    if (widget.isEditing) {
      await repo.update(cargo);
    } else {
      await repo.create(cargo);
    }

    // Сбрасываем кэш справочника грузов.
    cache.invalidate('cargo');

    if (!mounted) return;
    final notifier = context.read<CargoListNotifier>();
    await notifier.load();

    if (mounted) context.go('/cargo');
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
      title: widget.isEditing ? 'Редактирование груза' : 'Создание груза',
      isEditing: widget.isEditing,
      initialValues: {
        'name': _cargo?.name ?? '',
        'description': _cargo?.description ?? '',
        'weightPerUnit': _cargo?.weightPerUnit.toString() ?? '0',
        'volumePerUnit': _cargo?.volumePerUnit.toString() ?? '0',
      },
      fields: [
        FormFieldConfig(key: 'name', label: 'Название груза', maxLength: 100),
        FormFieldConfig(
          key: 'description',
          label: 'Описание',
          required: false,
          maxLines: 3,
          maxLength: 500,
        ),
        FormFieldConfig(
          key: 'weightPerUnit',
          label: 'Вес за единицу (кг)',
          type: FormFieldType.double,
        ),
        FormFieldConfig(
          key: 'volumePerUnit',
          label: 'Объём за единицу (м³)',
          type: FormFieldType.double,
        ),
      ],
      onSubmit: _save,
      onCancel: () => context.go('/cargo'),
    );
  }
}
