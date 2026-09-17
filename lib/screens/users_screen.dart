import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../models/app_user.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/cannot_delete_dialog.dart';
import '../utils/entity_dependencies.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _isLoading = true;
  String? _error;
  List<AppUser> _users = [];
  bool _includeDeleted = false;

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
      _users = await api.listUsers(includeDeleted: _includeDeleted);
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

  Future<void> _softDelete(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть пользователя?'),
        content: Text(
          'Пользователь «${user.username}» будет скрыт. '
          'Войти под ним будет невозможно, но запись останется в базе.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Скрыть'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<AuthApi>();
      await api.softDeleteUser(user.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Пользователь скрыт')));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _restore(AppUser user) async {
    try {
      final api = context.read<AuthApi>();
      await api.restoreUser(user.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь восстановлен')),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  /// Удалить пользователя навсегда.
  ///
  /// Перед удалением проверяем: если пользователь где-то используется
  /// (задачи как исполнитель / автор, склады как ответственный) —
  /// показываем диалог «Нельзя удалить» и НЕ удаляем.
  Future<void> _hardDelete(AppUser user) async {
    final blockers = await EntityDependencies.forUser(context, user.id);

    if (blockers.isNotEmpty) {
      if (!mounted) return;
      await showCannotDeleteDialog(
        context,
        entityName: user.fullName,
        blockers: blockers,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text(
          'Пользователь «${user.username}» будет удалён из базы '
          'безвозвратно. Восстановить его будет невозможно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить навсегда',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<AuthApi>();
      await api.hardDeleteUser(user.id);
      if (!mounted) return;
      setState(() {
        _users.removeWhere((u) => u.id == user.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь удалён навсегда')),
      );
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

    return MainScaffold(
      title: 'Пользователи',
      currentRoute: '/users',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Показать скрытых'),
                Switch(
                  value: _includeDeleted,
                  onChanged: (value) {
                    setState(() => _includeDeleted = value);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent(currentUser)),
        ],
      ),
    );
  }

  Widget _buildContent(AppUser? currentUser) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
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
          subtitle: Text(
            u.isDeleted ? '${u.email} • Скрыт' : u.email,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Роль — недоступна для себя и для скрытых.
              DropdownButton<Role>(
                value: u.role,
                onChanged: (isSelf || u.isDeleted)
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

              // Скрыть — для активных, не для себя.
              if (!u.isDeleted)
                IconButton(
                  icon: const Icon(Icons.visibility_off_outlined),
                  tooltip: 'Скрыть',
                  onPressed: isSelf ? null : () => _softDelete(u),
                ),

              // Восстановить — для скрытых.
              if (u.isDeleted)
                IconButton(
                  icon: const Icon(Icons.restore),
                  tooltip: 'Восстановить',
                  onPressed: () => _restore(u),
                ),

              // Удалить навсегда — для всех, кроме себя.
              if (!isSelf)
                IconButton(
                  icon: const Icon(Icons.delete_forever_outlined),
                  tooltip: 'Удалить навсегда',
                  onPressed: () => _hardDelete(u),
                ),
            ],
          ),
        );
      },
    );
  }
}
