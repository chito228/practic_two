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
  // ─── Общий пункт для всех ролей ──────────────────
  const home = MainNavItem(icon: Icons.home, label: 'Главная', route: '/');

  // ─── Админ ───────────────────────────────────────
  // Видит все бизнес-разделы + Пользователи.
  // НЕ видит: Диспетчерскую (только logist) и Статистику (только manager).
  if (auth.uiHasExactly(Role.admin)) {
    return const [
      home,
      MainNavItem(icon: Icons.people, label: 'Клиенты', route: '/clients'),
      MainNavItem(
        icon: Icons.receipt_long,
        label: 'Заказы',
        route: '/orders',
      ),
      MainNavItem(icon: Icons.inventory_2, label: 'Грузы', route: '/cargo'),
      MainNavItem(icon: Icons.route, label: 'Маршруты', route: '/routes'),
      MainNavItem(
        icon: Icons.local_shipping,
        label: 'Транспорт',
        route: '/vehicles',
      ),
      MainNavItem(
        icon: Icons.warehouse,
        label: 'Склады',
        route: '/warehouses',
      ),
      MainNavItem(
        icon: Icons.task_alt,
        label: 'Задачи',
        route: '/tasks',
      ),
      MainNavItem(
        icon: Icons.manage_accounts,
        label: 'Пользователи',
        route: '/users',
      ),
    ];
  }

  // ─── Manager и logist ────────────────────────────
  return [
    home,
    if (auth.uiHasExactly(Role.logist))
      const MainNavItem(
        icon: Icons.dashboard,
        label: 'Диспетчерская',
        route: '/dispatch',
      ),
    const MainNavItem(icon: Icons.people, label: 'Клиенты', route: '/clients'),
    const MainNavItem(
      icon: Icons.receipt_long,
      label: 'Заказы',
      route: '/orders',
    ),
    const MainNavItem(icon: Icons.inventory_2, label: 'Грузы', route: '/cargo'),
    const MainNavItem(icon: Icons.route, label: 'Маршруты', route: '/routes'),
    const MainNavItem(
      icon: Icons.local_shipping,
      label: 'Транспорт',
      route: '/vehicles',
    ),
    const MainNavItem(
      icon: Icons.warehouse,
      label: 'Склады',
      route: '/warehouses',
    ),
    const MainNavItem(
      icon: Icons.task_alt,
      label: 'Задачи',
      route: '/tasks',
    ),
    if (auth.hasExactly(Role.manager))
      const MainNavItem(
        icon: Icons.bar_chart,
        label: 'Статистика',
        route: '/stats',
      ),
  ];
}

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
    final route = currentRoute;
    if (route != null && route != '/') {
      // Ищем точное совпадение или префикс, исключая «/» — иначе
      // «/».startsWith('/') даст true и подсветит «Главная» везде.
      for (var i = 0; i < items.length; i++) {
        final r = items[i].route;
        if (r == '/') continue;
        if (route == r || route.startsWith('$r/')) {
          selected = i;
          break;
        }
      }
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
