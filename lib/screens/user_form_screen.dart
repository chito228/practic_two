import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../models/role.dart';
import '../repositories/user_repository.dart';
import '../state/user_list_notifier.dart';
import '../widgets/generic_form.dart';

class UserFormScreen extends StatefulWidget {
  final int? id;
  const UserFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  bool _isLoading = true;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final repo = context.read<UserRepository>();
      final u = await repo.findById(widget.id!);
      if (!mounted) return;
      if (u != null) _user = u;
    } else {
      _user = const AppUser(
        id: 0,
        username: '',
        fullName: '',
        email: '',
        role: Role.manager,
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save(Map<String, dynamic> values) async {
    final repo = context.read<UserRepository>();
    final notifier = context.read<UserListNotifier>();

    final roleValue = values['role'];
    final role = roleValue is Role
        ? roleValue
        : Role.fromString(roleValue?.toString());

    final password = (values['password'] as String?)?.trim() ?? '';

    if (widget.isEditing) {
      await repo.update(
        id: _user!.id,
        fullName: (values['fullName'] as String?)?.trim(),
        email: (values['email'] as String?)?.trim(),
        password: password.isEmpty ? null : password,
        role: role,
      );
    } else {
      await repo.create(
        username: (values['username'] as String?)?.trim() ?? '',
        password: password,
        fullName: (values['fullName'] as String?)?.trim() ?? '',
        email: (values['email'] as String?)?.trim() ?? '',
        role: role,
      );
    }

    if (!mounted) return;
    await notifier.load();
    if (mounted) context.go('/users');
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
      title: widget.isEditing
          ? 'Редактирование пользователя'
          : 'Создание пользователя',
      isEditing: widget.isEditing,
      initialValues: {
        'username': _user?.username ?? '',
        'fullName': _user?.fullName ?? '',
        'email': _user?.email ?? '',
        'password': '',
        'role': _user?.role,
      },
      fields: [
        // Логин нельзя менять при редактировании.
        if (!widget.isEditing)
          FormFieldConfig(
            key: 'username',
            label: 'Логин',
            maxLength: 30,
            validator: (value) {
              final s = value?.toString().trim() ?? '';
              if (s.isEmpty) return 'Введите логин';
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(s)) {
                return 'Только латиница, цифры и _';
              }
              if (!RegExp(r'[a-zA-Z]').hasMatch(s)) {
                return 'Обязательна хотя бы одна латинская буква';
              }
              return null;
            },
          ),
        FormFieldConfig(
          key: 'fullName',
          label: 'ФИО',
          maxLength: 100,
          validator: (value) {
            final s = value?.toString().trim() ?? '';
            if (s.isEmpty) return 'Введите ФИО';
            if (!RegExp(r'^[А-Яа-яЁё\s\-]+$').hasMatch(s)) {
              return 'Только русские буквы, пробел и дефис';
            }
            return null;
          },
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          type: FormFieldType.email,
          maxLength: 100,
        ),
        FormFieldConfig(
          key: 'password',
          label: widget.isEditing
              ? 'Новый пароль (оставьте пустым, чтобы не менять)'
              : 'Пароль',
          required: !widget.isEditing,
          maxLength: 64,
          validator: (value) {
            final s = value?.toString() ?? '';
            if (widget.isEditing && s.isEmpty) return null;
            if (s.isEmpty) return 'Введите пароль';
            if (s.length < 8) return 'Не короче 8 символов';
            if (!RegExp(r'[a-zA-Z]').hasMatch(s)) {
              return 'Обязательна латинская буква';
            }
            if (!RegExp(r'\d').hasMatch(s)) {
              return 'Обязательна цифра';
            }
            if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(s)) {
              return 'Обязателен специальный символ';
            }
            return null;
          },
        ),
        FormFieldConfig(
          key: 'role',
          label: 'Роль',
          type: FormFieldType.dropdown,
          options: Role.values
              .map(
                (r) => DropdownMenuItem<Role>(
                  value: r,
                  child: Text(r.label),
                ),
              )
              .toList(),
        ),
      ],
      onSubmit: _save,
      onCancel: () => context.go('/users'),
    );
  }
}
