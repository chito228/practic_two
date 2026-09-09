import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/cargo.dart';
import '../repositories/persistent_cargo_repository.dart';
import '../validators/validators.dart';
import '../state/cargo_list_notifier.dart';

class CargoFormScreen extends StatefulWidget {
  final int? id;
  const CargoFormScreen({super.key, this.id});

  bool get isEditing => id != null;
  String get title => isEditing ? 'Редактирование груза' : 'Создание груза';

  @override
  State<CargoFormScreen> createState() => _CargoFormScreenState();
}

class _CargoFormScreenState extends State<CargoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Cargo? _cargo;
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightPerUnitController = TextEditingController();
  final _volumePerUnitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _weightPerUnitController.dispose();
    _volumePerUnitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final repo = context.read<PersistentCargoRepository>();
      final cargo = await repo.findById(widget.id!);
      if (cargo != null) {
        _cargo = cargo;
        _nameController.text = cargo.name;
        _descriptionController.text = cargo.description ?? '';
        _weightPerUnitController.text = cargo.weightPerUnit.toString();
        _volumePerUnitController.text = cargo.volumePerUnit.toString();
      }
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
                  // Название груза (уникальное)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название груза',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final error = Validators.required(v, 'Название груза');
                      if (error != null) return error;
                      final repo = context.read<PersistentCargoRepository>();
                      return Validators.unique(
                        v,
                        repo.items,
                        (c) => c.name,
                        widget.id,
                        'Название груза',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Описание
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => null,
                  ),
                  const SizedBox(height: 16),

                  // Вес за единицу
                  TextFormField(
                    controller: _weightPerUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Вес за единицу (кг)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.positiveDouble(v, 'Вес за единицу'),
                  ),
                  const SizedBox(height: 16),

                  // Объём за единицу
                  TextFormField(
                    controller: _volumePerUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Объём за единицу (м³)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.positiveDouble(v, 'Объём за единицу'),
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
    if (_cargo == null) return false;
    return _nameController.text != _cargo!.name ||
        _descriptionController.text != (_cargo!.description ?? '') ||
        _weightPerUnitController.text != _cargo!.weightPerUnit.toString() ||
        _volumePerUnitController.text != _cargo!.volumePerUnit.toString();
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

    final repo = context.read<PersistentCargoRepository>();
    final cargo = Cargo(
      id: _cargo?.id ?? 0,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      weightPerUnit: double.tryParse(_weightPerUnitController.text) ?? 0.0,
      volumePerUnit: double.tryParse(_volumePerUnitController.text) ?? 0.0,
      orderIds: _cargo?.orderIds ?? [],
    );

    try {
      if (widget.isEditing) {
        await repo.update(cargo);
      } else {
        await repo.create(cargo);
      }
      
      final notifier = context.read<CargoListNotifier>();
      await notifier.load();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Груз обновлён' : 'Груз создан'),
          ),
        );
        Navigator.pop(context);
        context.go('/cargo');
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
