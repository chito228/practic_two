import 'package:flutter/material.dart';
import '../validators/validators.dart';

enum FormFieldType {
  text,
  number,
  double,
  dropdown,
  multiSelect,
  date,
  email,
  phone,
}

class FormFieldConfig {
  final String key;
  final String label;
  final FormFieldType type;
  final List<DropdownMenuItem<dynamic>>? options;
  final String? Function(dynamic)? validator;
  final int? maxLines;
  final int? maxLength;
  final bool required;
  final String? hintText;

  const FormFieldConfig({
    required this.key,
    required this.label,
    this.type = FormFieldType.text,
    this.options,
    this.validator,
    this.maxLines,
    this.maxLength,
    this.required = true,
    this.hintText,
  });
}

class GenericForm<T> extends StatefulWidget {
  final T entity;
  final List<FormFieldConfig> fields;
  final Future<void> Function(T) onSubmit;
  final bool isEditing;
  final Map<String, dynamic> initialValues;
  final Map<String, List<dynamic>>? optionsData;

  const GenericForm({
    super.key,
    required this.entity,
    required this.fields,
    required this.onSubmit,
    required this.isEditing,
    required this.initialValues,
    this.optionsData,
  });

  @override
  State<GenericForm<T>> createState() => _GenericFormState<T>();
}

class _GenericFormState<T> extends State<GenericForm<T>> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _values;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _values = Map.from(widget.initialValues);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_hasUnsavedChanges) {
          final shouldLeave = await _showUnsavedChangesDialog();
          if (shouldLeave) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Редактирование' : 'Создание'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...widget.fields.map((field) => _buildField(field)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.isEditing ? 'Сохранить' : 'Создать'),
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

  Widget _buildField(FormFieldConfig config) {
    final value = _values[config.key];

    switch (config.type) {
      case FormFieldType.text:
        return TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(
            labelText: config.label,
            hintText: config.hintText,
            border: const OutlineInputBorder(),
          ),
          maxLines: config.maxLines ?? 1,
          maxLength: config.maxLength,
          onChanged: (_) => _hasUnsavedChanges = true,
          onSaved: (v) => _values[config.key] = v ?? '',
          validator: (v) => _validateField(config, v),
        );

      case FormFieldType.number:
        return TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(
            labelText: config.label,
            hintText: config.hintText,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => _hasUnsavedChanges = true,
          onSaved: (v) => _values[config.key] = int.tryParse(v ?? '') ?? 0,
          validator: (v) => _validateField(config, v),
        );

      case FormFieldType.double:
        return TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(
            labelText: config.label,
            hintText: config.hintText,
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _hasUnsavedChanges = true,
          onSaved: (v) => _values[config.key] = double.tryParse(v ?? '') ?? 0.0,
          validator: (v) => _validateField(config, v),
        );

      case FormFieldType.email:
        return TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(
            labelText: config.label,
            hintText: config.hintText,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _hasUnsavedChanges = true,
          onSaved: (v) => _values[config.key] = v ?? '',
          validator: (v) => _validateField(config, v),
        );

      case FormFieldType.phone:
        return TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(
            labelText: config.label,
            hintText: config.hintText,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (_) => _hasUnsavedChanges = true,
          onSaved: (v) => _values[config.key] = v ?? '',
          validator: (v) => _validateField(config, v),
        );

      case FormFieldType.dropdown:
        return DropdownButtonFormField<dynamic>(
          value: value,
          decoration: InputDecoration(
            labelText: config.label,
            border: const OutlineInputBorder(),
          ),
          items: config.options,
          onChanged: (v) {
            setState(() {
              _values[config.key] = v;
              _hasUnsavedChanges = true;
            });
          },
          onSaved: (v) => _values[config.key] = v,
          validator: (v) => _validateField(config, v),
        );

      case FormFieldType.multiSelect:
        return _buildMultiSelectField(config);

      case FormFieldType.date:
        return TextFormField(
          initialValue: value?.toString().split(' ')[0],
          decoration: InputDecoration(
            labelText: config.label,
            hintText: 'ГГГГ-ММ-ДД',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(config.key),
            ),
          ),
          readOnly: true,
          onTap: () => _selectDate(config.key),
          validator: (v) => _validateField(config, v),
        );
    }
  }

  Widget _buildMultiSelectField(FormFieldConfig config) {
    final selectedIds = _values[config.key] as List<int>? ?? [];
    final items = widget.optionsData?[config.key] ?? [];

    return FormField<List<int>>(
      initialValue: selectedIds,
      validator: (value) => (value?.isEmpty ?? true) ? 'Выберите хотя бы один элемент' : null,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: config.label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final id = (item as dynamic).id as int;
              final name = (item as dynamic).name?.toString() ??
                  (item as dynamic).fullName?.toString() ??
                  'ID $id';
              final selected = field.value!.contains(id);
              return FilterChip(
                label: Text(name),
                selected: selected,
                onSelected: (_) {
                  final next = [...field.value!];
                  selected ? next.remove(id) : next.add(id);
                  field.didChange(next);
                  setState(() {
                    _values[config.key] = next;
                    _hasUnsavedChanges = true;
                  });
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(String key) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _values[key] = date;
        _hasUnsavedChanges = true;
      });
    }
  }

  String? _validateField(FormFieldConfig config, dynamic value) {
    final strValue = value?.toString().trim() ?? '';

    if (config.required && strValue.isEmpty) {
      return '${config.label} обязательно для заполнения';
    }

    if (config.validator != null) {
      return config.validator!(value);
    }

    // Стандартные валидации по типу
    switch (config.type) {
      case FormFieldType.email:
        return Validators.email(strValue);
      case FormFieldType.phone:
        return Validators.phone(strValue);
      case FormFieldType.number:
        return Validators.positiveNumber(strValue, config.label);
      case FormFieldType.double:
        return Validators.positiveDouble(strValue, config.label);
      default:
        return null;
    }
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
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      // Обновляем entity новыми значениями
      final updatedEntity = _updateEntity(widget.entity, _values);
      await widget.onSubmit(updatedEntity);
      _hasUnsavedChanges = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Запись обновлена' : 'Запись создана'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  T _updateEntity(T entity, Map<String, dynamic> values) {
    // Это должно быть реализовано в наследниках
    return entity;
  }
}
