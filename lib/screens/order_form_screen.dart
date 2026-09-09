import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/order.dart';
import '../models/client.dart';
import '../models/cargo.dart';
import '../models/route.dart' as model;
import '../repositories/persistent_order_repository.dart';
import '../repositories/persistent_client_repository.dart';
import '../repositories/persistent_cargo_repository.dart';
import '../repositories/persistent_route_repository.dart';
import '../validators/validators.dart';
import '../state/order_list_notifier.dart';

class OrderFormScreen extends StatefulWidget {
  final int? id;
  const OrderFormScreen({super.key, this.id});

  bool get isEditing => id != null;
  String get title => isEditing ? 'Редактирование заказа' : 'Создание заказа';

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Order? _order;
  
  final _orderNumberController = TextEditingController();
  final _cargoDescriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  
  int? _clientId;
  List<int> _cargoIds = [];
  List<int> _routeIds = [];
  String _status = 'in_transit';
  DateTime _shippingDate = DateTime.now();
  DateTime? _deliveryDate;
  
  List<Client> _clients = [];
  List<Cargo> _cargoList = [];
  List<model.Route> _routeList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _cargoDescriptionController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final clientRepo = context.read<PersistentClientRepository>();
    final cargoRepo = context.read<PersistentCargoRepository>();
    final routeRepo = context.read<PersistentRouteRepository>();
    
    _clients = await clientRepo.findAll();
    _cargoList = await cargoRepo.findAll();
    _routeList = await routeRepo.findAll();

    if (widget.isEditing) {
      final orderRepo = context.read<PersistentOrderRepository>();
      final order = await orderRepo.findById(widget.id!);
      if (order != null) {
        _order = order;
        _orderNumberController.text = order.orderNumber;
        _cargoDescriptionController.text = order.cargoDescription;
        _weightController.text = order.weight.toString();
        _volumeController.text = order.volume.toString();
        _clientId = order.clientId;
        _cargoIds = List.from(order.cargoIds);
        _routeIds = List.from(order.routeIds);
        _status = order.status;
        _shippingDate = order.shippingDate;
        _deliveryDate = order.deliveryDate;
      }
    } else {
      _order = Order(
        id: 0,
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        clientId: _clients.isNotEmpty ? _clients.first.id : 0,
        cargoIds: [],
        routeIds: [],
        cargoDescription: '',
        weight: 0.0,
        volume: 0.0,
        shippingDate: DateTime.now(),
        status: 'in_transit',
      );
      if (_clients.isNotEmpty) _clientId = _clients.first.id;
      _orderNumberController.text = _order!.orderNumber;
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
                  TextFormField(
                    controller: _orderNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Номер заказа',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final error = Validators.required(v, 'Номер заказа');
                      if (error != null) return error;
                      final repo = context.read<PersistentOrderRepository>();
                      return Validators.unique(
                        v,
                        repo.items,
                        (o) => o.orderNumber,
                        widget.id,
                        'Номер заказа',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: _clientId,
                    decoration: const InputDecoration(
                      labelText: 'Клиент',
                      border: OutlineInputBorder(),
                    ),
                    items: _clients.map((c) => 
                      DropdownMenuItem(value: c.id, child: Text(c.companyName))
                    ).toList(),
                    onChanged: (v) => setState(() => _clientId = v),
                    validator: (v) => v == null ? 'Выберите клиента' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildMultiSelectField(
                    label: 'Грузы',
                    items: _cargoList,
                    selectedIds: _cargoIds,
                    onChanged: (ids) => setState(() => _cargoIds = ids),
                    displayName: (c) => c.name,
                  ),
                  const SizedBox(height: 16),

                  _buildMultiSelectField(
                    label: 'Маршруты',
                    items: _routeList,
                    selectedIds: _routeIds,
                    onChanged: (ids) => setState(() => _routeIds = ids),
                    displayName: (r) => r.name,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _cargoDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание груза',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.required(v, 'Описание груза'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вес (кг)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.positiveDouble(v, 'Вес'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _volumeController,
                    decoration: const InputDecoration(
                      labelText: 'Объём (м³)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.positiveDouble(v, 'Объём'),
                  ),
                  const SizedBox(height: 16),

                  _buildDatePickerField(
                    label: 'Дата отправки',
                    value: _shippingDate,
                    onChanged: (date) => setState(() => _shippingDate = date),
                  ),
                  const SizedBox(height: 16),

                  _buildDatePickerField(
                    label: 'Дата доставки (опционально)',
                    value: _deliveryDate,
                    onChanged: (date) => setState(() => _deliveryDate = date),
                    optional: true,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Статус',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'in_transit', child: Text('В пути')),
                      DropdownMenuItem(value: 'delivered', child: Text('Доставлено')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Отменено')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'in_transit'),
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

  Widget _buildMultiSelectField<T>({
    required String label,
    required List<T> items,
    required List<int> selectedIds,
    required void Function(List<int>) onChanged,
    required String Function(T) displayName,
  }) {
    return FormField<List<int>>(
      initialValue: selectedIds,
      validator: (value) => (value?.isEmpty ?? true) ? 'Выберите хотя бы один элемент' : null,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final id = (item as dynamic).id as int;
              final selected = field.value!.contains(id);
              return FilterChip(
                label: Text(displayName(item)),
                selected: selected,
                onSelected: (_) {
                  final next = [...field.value!];
                  selected ? next.remove(id) : next.add(id);
                  field.didChange(next);
                  onChanged(next);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? value,
    required void Function(DateTime) onChanged,
    bool optional = false,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
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
              : (optional ? 'Не выбрано' : 'Выберите дату'),
        ),
      ),
    );
  }

  bool _hasUnsavedChanges() {
    if (_order == null) return false;
    return _orderNumberController.text != _order!.orderNumber ||
        _cargoDescriptionController.text != _order!.cargoDescription ||
        _weightController.text != _order!.weight.toString() ||
        _volumeController.text != _order!.volume.toString() ||
        _clientId != _order!.clientId ||
        _cargoIds.toString() != _order!.cargoIds.toString() ||
        _routeIds.toString() != _order!.routeIds.toString() ||
        _status != _order!.status ||
        _shippingDate != _order!.shippingDate ||
        _deliveryDate != _order!.deliveryDate;
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
    if (_clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите клиента')),
      );
      return;
    }

    final orderRepo = context.read<PersistentOrderRepository>();
    
    final order = Order(
      id: _order?.id ?? 0,
      orderNumber: _orderNumberController.text.trim(),
      clientId: _clientId!,
      cargoIds: _cargoIds,
      routeIds: _routeIds,
      cargoDescription: _cargoDescriptionController.text.trim(),
      weight: double.tryParse(_weightController.text) ?? 0.0,
      volume: double.tryParse(_volumeController.text) ?? 0.0,
      shippingDate: _shippingDate,
      deliveryDate: _deliveryDate,
      status: _status,
    );

    try {
      if (widget.isEditing) {
        await orderRepo.update(order);
      } else {
        await orderRepo.create(order);
      }
      
      final notifier = context.read<OrderListNotifier>();
      await notifier.load();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Заказ обновлён' : 'Заказ создан'),
          ),
        );
        Navigator.pop(context);
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
