import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../repositories/user_repository.dart';
import '../state/auth_notifier.dart';
import '../state/user_list_notifier.dart';

class UserDetailScreen extends StatelessWidget {
  final int id;
  const UserDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<UserRepository>(context);
    final currentUser = context.watch<AuthNotifier>().user;

    return FutureBuilder(
      future: repository.findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Пользователь')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Пользователь')),
            body: const Center(child: Text('Пользователь не найден')),
          );
        }
        final u = snapshot.data!;
        final isSelf = currentUser?.id == u.id;

        return Scaffold(
          appBar: AppBar(title: Text(u.fullName)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('ID', u.id.toString()),
                  _infoRow('ФИО', u.fullName),
                  _infoRow('Логин', u.username),
                  _infoRow('Email', u.email),
                  _infoRow('Роль', u.role.label),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/users'),
                        child: const Text('Назад'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            context.go('/users/${u.id}/edit'),
                        child: const Text('Редактировать'),
                      ),
                      if (!isSelf)
                        ElevatedButton(
                          onPressed: () => _delete(context, u.id),
                          child: const Text('Удалить'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: const Text(
          'Пользователь будет скрыт. Войти под ним будет невозможно.',
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
    if (!context.mounted) return;

    try {
      final repo = Provider.of<UserRepository>(context, listen: false);
      await repo.softDelete(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (!context.mounted) return;
    final notifier = Provider.of<UserListNotifier>(context, listen: false);
    await notifier.load();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Пользователь удалён')));
    context.go('/users');
  }
}
