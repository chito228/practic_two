import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => context.go('/clients'),
                child: const Text('Клиенты'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/orders'),
                child: const Text('Заказы'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
