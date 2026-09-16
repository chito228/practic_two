import 'package:go_router/go_router.dart';

import 'models/role.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/users_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/client_detail_screen.dart';
import 'screens/client_form_screen.dart';
import 'screens/order_list_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_form_screen.dart';
import 'screens/dispatch_screen.dart';
import 'screens/cargo_list_screen.dart';
import 'screens/cargo_detail_screen.dart';
import 'screens/cargo_form_screen.dart';
import 'screens/route_list_screen.dart';
import 'screens/route_detail_screen.dart';
import 'screens/route_form_screen.dart';
import 'screens/vehicle_list_screen.dart';
import 'screens/vehicle_detail_screen.dart';
import 'screens/vehicle_form_screen.dart';
import 'screens/not_found_screen.dart';
import 'state/auth_notifier.dart';

/// Фабрика роутера. Вызывается из main() с AuthNotifier.
/// refreshListenable: auth — при notifyListeners() пересчитывается redirect.
late final GoRouter appRouter;

void buildRouter(AuthNotifier auth) {
  appRouter = GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      // 1. Не вошёл и идёт на закрытый экран → /login?from=...
      if (!loggedIn && !isPublic) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      // 2. Вошёл и идёт на /login или /register → на главную.
      if (loggedIn && isPublic) {
        return '/';
      }

      return null;
    },
    routes: [
      // ─── Публичные маршруты ──────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),

      // ─── Главная ─────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // ─── Статистика (только manager) ─────────────────
      GoRoute(
        path: '/stats',
        redirect: (context, state) =>
            auth.hasExactly(Role.manager) ? null : '/forbidden',
        builder: (context, state) => const StatsScreen(),
      ),

      // ─── Пользователи (только admin) ─────────────────
      GoRoute(
        path: '/users',
        redirect: (context, state) =>
            auth.has(Role.admin) ? null : '/forbidden',
        builder: (context, state) => const UsersScreen(),
      ),

      // ─── Клиенты ─────────────────────────────────────
      // Список и детали — все роли.
      // Создание/редактирование — logist и выше.
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientListScreen(),
      ),
      GoRoute(
        path: '/clients/create',
        redirect: (context, state) =>
            auth.has(Role.logist) ? null : '/forbidden',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        redirect: (context, state) =>
            auth.has(Role.logist) ? null : '/forbidden',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ClientFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ClientDetailScreen(id: id ?? 0);
        },
      ),

      // ─── Заказы ──────────────────────────────────────
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderListScreen(),
      ),
      GoRoute(
        path: '/orders/create',
        redirect: (context, state) =>
            auth.has(Role.logist) ? null : '/forbidden',
        builder: (context, state) => const OrderFormScreen(),
      ),
      GoRoute(
        path: '/orders/:id/edit',
        redirect: (context, state) =>
            auth.has(Role.logist) ? null : '/forbidden',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return OrderFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return OrderDetailScreen(id: id ?? 0);
        },
      ),

      // ─── Диспетчерская (только logist) ───────────────
      // Уникальный экран логиста. hasExactly — не пропустит
      // ни manager, ни admin. Это требование пункта 8 ПР5.
      GoRoute(
        path: '/dispatch',
        redirect: (context, state) =>
            auth.hasExactly(Role.logist) ? null : '/forbidden',
        builder: (context, state) => const DispatchScreen(),
      ),

      // ─── Грузы ───────────────────────────────────────
      // Создание/редактирование — только admin.
      GoRoute(
        path: '/cargo',
        builder: (context, state) => const CargoListScreen(),
      ),
      GoRoute(
        path: '/cargo/create',
        redirect: (context, state) =>
            auth.has(Role.admin) ? null : '/forbidden',
        builder: (context, state) => const CargoFormScreen(),
      ),
      GoRoute(
        path: '/cargo/:id/edit',
        redirect: (context, state) =>
            auth.has(Role.admin) ? null : '/forbidden',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return CargoFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/cargo/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return CargoDetailScreen(id: id ?? 0);
        },
      ),

      // ─── Маршруты ────────────────────────────────────
      GoRoute(
        path: '/routes',
        builder: (context, state) => const RouteListScreen(),
      ),
      GoRoute(
        path: '/routes/create',
        redirect: (context, state) =>
            auth.has(Role.logist) ? null : '/forbidden',
        builder: (context, state) => const RouteFormScreen(),
      ),
      GoRoute(
        path: '/routes/:id/edit',
        redirect: (context, state) =>
            auth.has(Role.logist) ? null : '/forbidden',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return RouteFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/routes/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return RouteDetailScreen(id: id ?? 0);
        },
      ),

      // ─── Транспорт ───────────────────────────────────
      // Создание/редактирование — только admin.
      // Смена статуса — logist и admin (через отдельный эндпоинт).
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => const VehicleListScreen(),
      ),
      GoRoute(
        path: '/vehicles/create',
        redirect: (context, state) =>
            auth.has(Role.admin) ? null : '/forbidden',
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: '/vehicles/:id/edit',
        redirect: (context, state) =>
            auth.has(Role.admin) ? null : '/forbidden',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return VehicleFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/vehicles/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return VehicleDetailScreen(id: id ?? 0);
        },
      ),
    ],

    errorBuilder: (context, state) => NotFoundScreen(
      location: state.uri.toString(),
    ),
  );
}
