import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '403',
                style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'У вашей роли нет доступа к этому разделу.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('На главную'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await context.read<AuthNotifier>().logout();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Выйти'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
