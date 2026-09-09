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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuButton(
                  context,
                  'Клиенты',
                  '/clients',
                  Icons.business,
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  context,
                  'Заказы',
                  '/orders',
                  Icons.local_shipping,
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  context,
                  'Грузы',
                  '/cargo',
                  Icons.inventory,
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  context,
                  'Маршруты',
                  '/routes',
                  Icons.route,
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  context,
                  'Транспорт',
                  '/vehicles',
                  Icons.directions_car,
                ),
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
    IconData icon,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => context.go(route),
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
