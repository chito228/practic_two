import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/order_repository.dart';
import '../repositories/client_repository.dart';
import '../models/order.dart';
import '../models/client.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargoController = TextEditingController();
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  int? _clientId;
  String _status = 'в пути';
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final repository = Provider.of<ClientRepository>(context, listen: false);
    _clients = await repository.findAll();
    if (_clients.isNotEmpty) {
      setState(() => _clientId = _clients.first.id);
    }
  }

  @override
  void dispose() {
    _cargoController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание заказа'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _clientId,
                  decoration: const InputDecoration(
                    labelText: 'Клиент',
                    border: OutlineInputBorder(),
                  ),
                  items: _clients.map<DropdownMenuItem<int>>((Client c) {
                    return DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _clientId = v),
                  validator: (v) => v == null ? 'Выберите клиента' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cargoController,
                  decoration: const InputDecoration(
                    labelText: 'Описание груза',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Введите описание груза' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Вес (кг)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Введите вес' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _volumeController,
                  decoration: const InputDecoration(
                    labelText: 'Объём (м³)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Введите объём' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Статус',
                    border: OutlineInputBorder(),
                  ),
                  items: ['в пути', 'доставлено', 'отменено']
                      .map((s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? 'в пути'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/orders'),
                      child: const Text('Отмена'),
                    ),
                    ElevatedButton(
                      onPressed: _saveOrder,
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null) return;

    final repository = Provider.of<OrderRepository>(context, listen: false);
    final newOrder = Order(
      id: 0,
      clientId: _clientId!,
      cargoDescription: _cargoController.text,
      weight: double.tryParse(_weightController.text) ?? 0,
      volume: double.tryParse(_volumeController.text) ?? 0,
      sendDate: DateTime.now(),
      status: _status,
    );

    try {
      await repository.create(newOrder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ создан')),
        );
        context.go('/orders');
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
