import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final int? minLength;
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
    this.minLength,
    this.required = true,
    this.hintText,
  });
}

class GenericForm extends StatefulWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  final bool isEditing;
  final Map<String, dynamic> initialValues;
  final Map<String, List<dynamic>>? optionsData;
  final VoidCallback? onCancel;

  const GenericForm({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    required this.isEditing,
    required this.initialValues,
    this.optionsData,
    this.onCancel,
  });

  @override
  State<GenericForm> createState() => _GenericFormState();
}

class _GenericFormState extends State<GenericForm> {
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
          if (shouldLeave && mounted) _handleCancel();
        } else {
          _handleCancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleCancel,
          ),
          title: Text(widget.title),
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
                        onPressed: _handleCancel,
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

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildField(FormFieldConfig config) {
    final value = _values[config.key];

    switch (config.type) {
      case FormFieldType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            initialValue: value?.toString(),
            decoration: InputDecoration(
              labelText: config.label,
              hintText: config.hintText,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            maxLines: config.maxLines ?? 1,
            inputFormatters: config.maxLength != null
                ? [LengthLimitingTextInputFormatter(config.maxLength)]
                : null,
            onChanged: (v) {
              _values[config.key] = v;
              _hasUnsavedChanges = true;
            },
            validator: (v) => _validateField(config, v),
          ),
        );

      case FormFieldType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            initialValue: value?.toString(),
            decoration: InputDecoration(
              labelText: config.label,
              hintText: config.hintText,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              _values[config.key] = v;
              _hasUnsavedChanges = true;
            },
            validator: (v) => _validateField(config, v),
          ),
        );

      case FormFieldType.double:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            initialValue: value?.toString(),
            decoration: InputDecoration(
              labelText: config.label,
              hintText: config.hintText,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              _values[config.key] = v;
              _hasUnsavedChanges = true;
            },
            validator: (v) => _validateField(config, v),
          ),
        );

      case FormFieldType.email:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            initialValue: value?.toString(),
            decoration: InputDecoration(
              labelText: config.label,
              hintText: config.hintText,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) {
              _values[config.key] = v;
              _hasUnsavedChanges = true;
            },
            validator: (v) => _validateField(config, v),
          ),
        );

      case FormFieldType.phone:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            initialValue: value?.toString(),
            decoration: InputDecoration(
              labelText: config.label,
              hintText: config.hintText,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            keyboardType: TextInputType.phone,
            onChanged: (v) {
              _values[config.key] = v;
              _hasUnsavedChanges = true;
            },
            validator: (v) => _validateField(config, v),
          ),
        );

      case FormFieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DropdownButtonFormField<dynamic>(
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
            validator: (v) => _validateField(config, v),
          ),
        );

      case FormFieldType.multiSelect:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildMultiSelectField(config),
        );

      case FormFieldType.date:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            key: ValueKey('${config.key}_${value?.toString()}'),
            initialValue: value != null
                ? (value is DateTime
                    ? value.toLocal().toString().split(' ')[0]
                    : value.toString())
                : null,
            decoration: InputDecoration(
              labelText: config.label,
              hintText: 'ГГГГ-ММ-ДД',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(config.key),
              ),
              counterText: '',
            ),
            readOnly: true,
            onTap: () => _selectDate(config.key),
            validator: (v) => _validateField(config, v),
          ),
        );
    }
  }

  Widget _buildMultiSelectField(FormFieldConfig config) {
    final selectedIds = (_values[config.key] as List<int>?) ?? [];
    final items = widget.optionsData?[config.key] ?? [];

    return FormField<List<int>>(
      initialValue: selectedIds,
      validator: (value) =>
          (value?.isEmpty ?? true) ? 'Выберите хотя бы один элемент' : null,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: config.label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Нет доступных значений',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.map((item) {
                    final id = (item as dynamic).id as int;
                    final name = (item as dynamic).name?.toString() ??
                        (item as dynamic).fullName?.toString() ??
                        (item as dynamic).companyName?.toString() ??
                        (item as dynamic).plateNumber?.toString() ??
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
    final current = _values[key];
    final date = await showDatePicker(
      context: context,
      initialDate: current is DateTime ? current : DateTime.now(),
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

    switch (config.type) {
      case FormFieldType.email:
        return Validators.email(strValue);
      case FormFieldType.phone:
        return Validators.phone(strValue);
      case FormFieldType.number:
        return Validators.positiveNumber(strValue, config.label);
      case FormFieldType.double:
        return Validators.positiveDouble(strValue, config.label);
      case FormFieldType.text:
        if (config.minLength != null &&
            strValue.isNotEmpty &&
            strValue.length < config.minLength!) {
          return '${config.label} должно быть не короче ${config.minLength} символов';
        }
        if (config.maxLength != null &&
            strValue.isNotEmpty &&
            strValue.length > config.maxLength!) {
          return '${config.label} не может быть длиннее ${config.maxLength} символов';
        }
        return null;
      default:
        return null;
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Несохранённые изменения'),
            content: const Text(
                'У вас есть несохранённые изменения. Вы уверены, что хотите выйти?'),
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

    setState(() => _isSaving = true);

    try {
      await widget.onSubmit(_values);
      _hasUnsavedChanges = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Запись обновлена' : 'Запись создана'),
          ),
        );
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
}
