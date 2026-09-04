import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/client_repository.dart';
import '../models/client.dart';

class ClientEditScreen extends StatefulWidget {
  final int id;
  const ClientEditScreen({super.key, required this.id});

  @override
  State<ClientEditScreen> createState() => _ClientEditScreenState();
}

class _ClientEditScreenState extends State<ClientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  Client? _client;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    final repository = Provider.of<ClientRepository>(context, listen: false);
    final client = await repository.findById(widget.id);
    setState(() {
      _client = client;
      _isLoading = false;
      if (client != null) {
        _nameController.text = client.name;
        _contactPersonController.text = client.contactPerson;
        _phoneController.text = client.phone;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактирование клиента')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактирование клиента')),
        body: const Center(child: Text('Клиент не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование клиента'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название компании',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Контактное лицо',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Введите контактное лицо' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Введите телефон' : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/clients'),
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    onPressed: _saveClient,
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_client == null) return;

    final repository = Provider.of<ClientRepository>(context, listen: false);
    final updatedClient = _client!.copyWith(
      name: _nameController.text,
      contactPerson: _contactPersonController.text,
      phone: _phoneController.text,
    );

    try {
      await repository.update(updatedClient);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Клиент обновлён')),
        );
        context.go('/clients');
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
