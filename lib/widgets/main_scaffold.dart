import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../state/auth_notifier.dart';
import 'adaptive_scaffold.dart';

class MainNavItem {
  final IconData icon;
  final String label;
  final String route;

  const MainNavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

List<MainNavItem> navItemsFor(AuthNotifier auth) {
  return [
    if (auth.uiHasExactly(Role.logist))
      const MainNavItem(
        icon: Icons.dashboard,
        label: 'Диспетчерская',
        route: '/dispatch',
      ),
    const MainNavItem(icon: Icons.people, label: 'Клиенты', route: '/clients'),
    const MainNavItem(
        icon: Icons.receipt_long, label: 'Заказы', route: '/orders'),
    const MainNavItem(
        icon: Icons.inventory_2, label: 'Грузы', route: '/cargo'),
    const MainNavItem(icon: Icons.route, label: 'Маршруты', route: '/routes'),
    const MainNavItem(
        icon: Icons.local_shipping, label: 'Транспорт', route: '/vehicles'),
    if (auth.hasExactly(Role.manager))
      const MainNavItem(
          icon: Icons.bar_chart, label: 'Статистика', route: '/stats'),
    if (auth.hasExactly(Role.admin))
      const MainNavItem(
          icon: Icons.manage_accounts,
          label: 'Пользователи',
          route: '/users'),
  ];
}

/// Общий каркас. Использовать на основных экранах.
class MainScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? currentRoute;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final items = navItemsFor(auth);

    int selected = 0;
    // Локальная переменная — чтобы Dart мог промоутить String? до String.
    final route = currentRoute;
    if (route != null) {
      final idx = items.indexWhere((it) => route.startsWith(it.route));
      if (idx != -1) selected = idx;
    }

    return AdaptiveScaffold(
      title: title,
      items: items
          .map((e) => AdaptiveNavItem(icon: e.icon, label: e.label))
          .toList(),
      selectedIndex: selected,
      onDestinationSelected: (i) {
        if (i >= 0 && i < items.length) context.go(items[i].route);
      },
      actions: actions,
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
