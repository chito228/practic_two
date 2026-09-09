import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/client.dart';
import '../repositories/persistent_client_repository.dart';
import '../validators/validators.dart';
import '../state/client_list_notifier.dart';

class ClientFormScreen extends StatefulWidget {
  final int? id;
  const ClientFormScreen({super.key, this.id});

  bool get isEditing => id != null;
  String get title => isEditing ? 'Редактирование клиента' : 'Создание клиента';

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  Client? _client;
  
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (widget.isEditing) {
        final repo = context.read<PersistentClientRepository>();
        final client = await repo.findById(widget.id!);
        if (client != null) {
          _client = client;
          _companyNameController.text = client.companyName;
          _contactPersonController.text = client.contactPerson;
          _phoneController.text = client.phone;
          _emailController.text = client.email;
          _addressController.text = client.address ?? '';
        }
      } else {
        _client = Client(
          id: 0,
          companyName: '',
          contactPerson: '',
          phone: '',
          email: '',
          address: null,  // ← исправлено: null вместо ''
          orderIds: [],
        );
      }
    } catch (e) {
      print('Ошибка загрузки: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          if (shouldLeave && mounted) {
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            Navigator.pop(context);
          }
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
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Название компании',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final error = Validators.required(v, 'Название компании');
                      if (error != null) return error;
                      final repo = context.read<PersistentClientRepository>();
                      return Validators.unique(
                        v,
                        repo.items,
                        (c) => c.companyName,
                        widget.id,
                        'Название компании',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _contactPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Контактное лицо',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.required(v, 'Контактное лицо'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      border: OutlineInputBorder(),
                      hintText: '+7-999-111-22-33',
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Телефон обязателен для заполнения';
                      }
                      if (!RegExp(r'^[\+\d\s\-\(\)]+$').hasMatch(v.trim())) {
                        return 'Введите корректный номер телефона';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      hintText: 'example@mail.ru',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email обязателен для заполнения';
                      }
                      final emailError = Validators.email(v);
                      if (emailError != null) return emailError;
                      final repo = context.read<PersistentClientRepository>();
                      return Validators.unique(
                        v,
                        repo.items,
                        (c) => c.email,
                        widget.id,
                        'Email',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес (необязательно)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
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

  bool _hasUnsavedChanges() {
    if (_client == null) return false;
    return _companyNameController.text != _client!.companyName ||
        _contactPersonController.text != _client!.contactPerson ||
        _phoneController.text != _client!.phone ||
        _emailController.text != _client!.email ||
        _addressController.text != (_client!.address ?? '');
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = context.read<PersistentClientRepository>();
      
      // Обработка address: если пустая строка → null
      final addressValue = _addressController.text.trim();
      
      final newClient = Client(
        id: _client?.id ?? 0,
        companyName: _companyNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: addressValue.isEmpty ? null : addressValue,
        orderIds: _client?.orderIds ?? [],
      );

      if (widget.isEditing) {
        await repo.update(newClient);
      } else {
        await repo.create(newClient);
      }
      
      final notifier = context.read<ClientListNotifier>();
      await notifier.load();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Клиент обновлён' : 'Клиент создан'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        context.go('/clients');
      }
    } catch (e) {
      print('Ошибка сохранения: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
