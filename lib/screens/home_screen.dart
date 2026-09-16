import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../state/auth_notifier.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Главная'),
            if (user != null)
              Text(
                '${user.fullName} — ${user.role.label}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await context.read<AuthNotifier>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─── Диспетчерская — только для logist ───
                if (auth.uiHasExactly(Role.logist)) ...[
                  _buildMenuButton(
                    context,
                    'Диспетчерская',
                    '/dispatch',
                  ),
                  const SizedBox(height: 12),
                ],

                _buildMenuButton(context, 'Клиенты', '/clients'),
                const SizedBox(height: 12),
                _buildMenuButton(context, 'Заказы', '/orders'),
                const SizedBox(height: 12),
                _buildMenuButton(context, 'Грузы', '/cargo'),
                const SizedBox(height: 12),
                _buildMenuButton(context, 'Маршруты', '/routes'),
                const SizedBox(height: 12),
                _buildMenuButton(context, 'Транспорт', '/vehicles'),

                // ─── Статистика — только для manager ───
                if (auth.hasExactly(Role.manager)) ...[
                  const SizedBox(height: 12),
                  _buildMenuButton(
                    context,
                    'Статистика',
                    '/stats',
                  ),
                ],

                // ─── Пользователи — только для admin ───
                if (auth.hasExactly(Role.admin)) ...[
                  const SizedBox(height: 12),
                  _buildMenuButton(
                    context,
                    'Пользователи',
                    '/users',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    String route,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => context.go(route),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
