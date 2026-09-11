import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/client_detail_screen.dart';
import 'screens/client_form_screen.dart';
import 'screens/order_list_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_form_screen.dart';
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

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/clients',
      builder: (context, state) => const ClientListScreen(),
    ),
    GoRoute(
      path: '/clients/create',
      builder: (context, state) => const ClientFormScreen(),
    ),
    GoRoute(
      path: '/clients/:id/edit',
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

    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderListScreen(),
    ),
    GoRoute(
      path: '/orders/create',
      builder: (context, state) => const OrderFormScreen(),
    ),
    GoRoute(
      path: '/orders/:id/edit',
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

    GoRoute(
      path: '/cargo',
      builder: (context, state) => const CargoListScreen(),
    ),
    GoRoute(
      path: '/cargo/create',
      builder: (context, state) => const CargoFormScreen(),
    ),
    GoRoute(
      path: '/cargo/:id/edit',
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

    GoRoute(
      path: '/routes',
      builder: (context, state) => const RouteListScreen(),
    ),
    GoRoute(
      path: '/routes/create',
      builder: (context, state) => const RouteFormScreen(),
    ),
    GoRoute(
      path: '/routes/:id/edit',
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

    GoRoute(
      path: '/vehicles',
      builder: (context, state) => const VehicleListScreen(),
    ),
    GoRoute(
      path: '/vehicles/create',
      builder: (context, state) => const VehicleFormScreen(),
    ),
    GoRoute(
      path: '/vehicles/:id/edit',
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
