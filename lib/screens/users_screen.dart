import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../models/app_user.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _isLoading = true;
  String? _error;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthApi>();
      _users = await api.listUsers();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(AppUser user, Role newRole) async {
    try {
      final api = context.read<AuthApi>();
      final updated = await api.updateUser(id: user.id, role: newRole);
      if (!mounted) return;
      setState(() {
        final i = _users.indexWhere((u) => u.id == user.id);
        if (i != -1) _users[i] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Роль изменена на «${newRole.label}»')),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: Text(
          'Пользователь «${user.username}» будет скрыт из списка. '
          'Войти под ним будет невозможно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<AuthApi>();
      await api.deleteUser(user.id);
      if (!mounted) return;
      setState(() {
        _users.removeWhere((u) => u.id == user.id);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Пользователь удалён')));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthNotifier>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи')),
      body: _buildContent(currentUser),
    );
  }

  Widget _buildContent(AppUser? currentUser) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('Пользователи не найдены'));
    }

    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final u = _users[index];
        final isSelf = currentUser?.id == u.id;

        return ListTile(
          title: Text('${u.fullName} (@${u.username})'),
          subtitle: Text(u.email),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Role>(
                value: u.role,
                onChanged: isSelf
                    ? null
                    : (v) {
                        if (v != null && v != u.role) {
                          _changeRole(u, v);
                        }
                      },
                items: Role.values
                    .map(
                      (r) => DropdownMenuItem<Role>(
                        value: r,
                        child: Text(r.label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Удалить',
                onPressed: isSelf ? null : () => _deleteUser(u),
              ),
            ],
          ),
        );
      },
    );
  }
}
