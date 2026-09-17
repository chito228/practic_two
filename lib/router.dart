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
import 'screens/warehouse_list_screen.dart';
import 'screens/warehouse_detail_screen.dart';
import 'screens/warehouse_form_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/task_form_screen.dart';
import 'screens/not_found_screen.dart';
import 'state/auth_notifier.dart';

late final GoRouter appRouter;

/// Проверка: пользователь — admin, manager или logist.
/// Используется для бизнес-разделов, куда admin теперь тоже пускаем.
bool _canViewBusiness(AuthNotifier auth) =>
    auth.hasExactly(Role.admin) ||
    auth.hasExactly(Role.manager) ||
    auth.hasExactly(Role.logist);

/// Проверка: пользователь — logist или admin.
/// Используется для форм создания/редактирования бизнес-сущностей.
bool _canEditBusiness(AuthNotifier auth) =>
    auth.hasExactly(Role.logist) || auth.hasExactly(Role.admin);

/// Проверка: пользователь — manager или admin.
/// Используется для форм задач.
bool _canEditTasks(AuthNotifier auth) =>
    auth.hasExactly(Role.manager) || auth.hasExactly(Role.admin);

void buildRouter(AuthNotifier auth) {
  appRouter = GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }
      if (loggedIn && isPublic) {
        return '/';
      }
      return null;
    },
    routes: [
      // ─── Публичные маршруты ──────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(from: state.uri.queryParameters['from']),
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
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

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
            auth.hasExactly(Role.admin) ? null : '/forbidden',
        builder: (context, state) => const UsersScreen(),
      ),

      // ─── Клиенты ─────────────────────────────────────
      GoRoute(
        path: '/clients',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const ClientListScreen(),
      ),
      GoRoute(
        path: '/clients/create',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return ClientFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/clients/:id',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ClientDetailScreen(id: id);
        },
      ),

      // ─── Заказы ──────────────────────────────────────
      GoRoute(
        path: '/orders',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const OrderListScreen(),
      ),
      GoRoute(
        path: '/orders/create',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const OrderFormScreen(),
      ),
      GoRoute(
        path: '/orders/:id/edit',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return OrderFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/orders/:id',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderDetailScreen(id: id);
        },
      ),

      // ─── Диспетчерская (только logist) ───────────────
      GoRoute(
        path: '/dispatch',
        redirect: (context, state) =>
            auth.hasExactly(Role.logist) ? null : '/forbidden',
        builder: (context, state) => const DispatchScreen(),
      ),

      // ─── Грузы ───────────────────────────────────────
      GoRoute(
        path: '/cargo',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const CargoListScreen(),
      ),
      GoRoute(
        path: '/cargo/create',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const CargoFormScreen(),
      ),
      GoRoute(
        path: '/cargo/:id/edit',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return CargoFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/cargo/:id',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CargoDetailScreen(id: id);
        },
      ),

      // ─── Маршруты ────────────────────────────────────
      GoRoute(
        path: '/routes',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const RouteListScreen(),
      ),
      GoRoute(
        path: '/routes/create',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const RouteFormScreen(),
      ),
      GoRoute(
        path: '/routes/:id/edit',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return RouteFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/routes/:id',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RouteDetailScreen(id: id);
        },
      ),

      // ─── Транспорт ───────────────────────────────────
      GoRoute(
        path: '/vehicles',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const VehicleListScreen(),
      ),
      GoRoute(
        path: '/vehicles/create',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: '/vehicles/:id/edit',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return VehicleFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/vehicles/:id',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return VehicleDetailScreen(id: id);
        },
      ),

      // ─── Склады ──────────────────────────────────────
      GoRoute(
        path: '/warehouses',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const WarehouseListScreen(),
      ),
      GoRoute(
        path: '/warehouses/create',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const WarehouseFormScreen(),
      ),
      GoRoute(
        path: '/warehouses/:id/edit',
        redirect: (context, state) =>
            _canEditBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return WarehouseFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/warehouses/:id',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return WarehouseDetailScreen(id: id);
        },
      ),

      // ─── Задачи ──────────────────────────────────────
      GoRoute(
        path: '/tasks',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) => const TaskListScreen(),
      ),
      GoRoute(
        path: '/tasks/create',
        redirect: (context, state) =>
            _canEditTasks(auth) ? null : '/forbidden',
        builder: (context, state) => const TaskFormScreen(),
      ),
      GoRoute(
        path: '/tasks/:id/edit',
        redirect: (context, state) =>
            _canEditTasks(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return TaskFormScreen(id: id);
        },
      ),
      GoRoute(
        path: '/tasks/:id',
        redirect: (context, state) =>
            _canViewBusiness(auth) ? null : '/forbidden',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TaskDetailScreen(id: id);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}
