import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/client.dart';
import '../repositories/persistent_client_repository.dart';
import '../widgets/generic_form.dart';
import '../state/client_list_notifier.dart';

class ClientFormScreen extends StatefulWidget {
  final int? id;
  const ClientFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  bool _isLoading = true;
  Client? _client;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading && _client == null) _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final repo = context.read<PersistentClientRepository>();
      final c = await repo.findById(widget.id!);
      if (c != null) _client = c;
    } else {
      _client = Client(
        id: 0,
        companyName: '',
        contactPerson: '',
        phone: '',
        email: '',
        address: null,
        orderIds: [],
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save(Map<String, dynamic> values) async {
    final repo = context.read<PersistentClientRepository>();
    final addressValue = (values['address'] as String?)?.trim() ?? '';

    final newClient = Client(
      id: _client?.id ?? 0,
      companyName: (values['companyName'] as String?) ?? '',
      contactPerson: (values['contactPerson'] as String?) ?? '',
      phone: (values['phone'] as String?) ?? '',
      email: (values['email'] as String?) ?? '',
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

    if (mounted) context.go('/clients');
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
      title: widget.isEditing ? 'Редактирование клиента' : 'Создание клиента',
      isEditing: widget.isEditing,
      initialValues: {
        'companyName': _client?.companyName ?? '',
        'contactPerson': _client?.contactPerson ?? '',
        'phone': _client?.phone ?? '',
        'email': _client?.email ?? '',
        'address': _client?.address ?? '',
      },
      fields: [
        FormFieldConfig(
          key: 'companyName',
          label: 'Название компании',
          maxLength: 200,
        ),
        FormFieldConfig(
          key: 'contactPerson',
          label: 'Контактное лицо',
          maxLength: 150,
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Телефон',
          type: FormFieldType.phone,
          hintText: '+7-999-111-22-33',
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          type: FormFieldType.email,
          hintText: 'example@mail.ru',
        ),
        FormFieldConfig(
          key: 'address',
          label: 'Адрес (необязательно)',
          required: false,
          maxLines: 2,
          maxLength: 300,
          minLength: 5,
        ),
      ],
      onSubmit: _save,
      onCancel: () => context.go('/clients'),
    );
  }
}
