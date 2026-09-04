import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/order_repository.dart';
import '../repositories/client_repository.dart';
import '../models/order.dart';
import '../models/client.dart';

class OrderEditScreen extends StatefulWidget {
  final int id;
  const OrderEditScreen({super.key, required this.id});

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargoController = TextEditingController();
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  int? _clientId;
  String _status = 'в пути';
  List<Client> _clients = [];
  bool _isLoading = true;
  Order? _order;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final orderRepo = Provider.of<OrderRepository>(context, listen: false);
    final clientRepo = Provider.of<ClientRepository>(context, listen: false);

    final order = await orderRepo.findById(widget.id);
    _clients = await clientRepo.findAll();

    setState(() {
      _order = order;
      _isLoading = false;
      if (order != null) {
        _cargoController.text = order.cargoDescription;
        _weightController.text = order.weight.toString();
        _volumeController.text = order.volume.toString();
        _clientId = order.clientId;
        _status = order.status;
      }
    });
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактирование заказа')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактирование заказа')),
        body: const Center(child: Text('Заказ не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование заказа'),
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
    if (_clientId == null || _order == null) return;

    final repository = Provider.of<OrderRepository>(context, listen: false);
    final updatedOrder = _order!.copyWith(
      clientId: _clientId!,
      cargoDescription: _cargoController.text,
      weight: double.tryParse(_weightController.text) ?? 0,
      volume: double.tryParse(_volumeController.text) ?? 0,
      status: _status,
    );

    try {
      await repository.update(updatedOrder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ обновлён')),
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
