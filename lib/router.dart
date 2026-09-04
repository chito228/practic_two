import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/client_detail_screen.dart';
import 'screens/client_create_screen.dart';
import 'screens/client_edit_screen.dart';
import 'screens/order_list_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_create_screen.dart';
import 'screens/order_edit_screen.dart';
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
      builder: (context, state) => const ClientCreateScreen(),
    ),
    GoRoute(
      path: '/clients/:id/edit',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.tryParse(idStr);
        if (id == null) {
          return NotFoundScreen(location: state.uri.toString());
        }
        return ClientEditScreen(id: id);
      },
    ),
    GoRoute(
      path: '/clients/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.tryParse(idStr);
        if (id == null) {
          return NotFoundScreen(location: state.uri.toString());
        }
        return ClientDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) {
        final query = state.uri.queryParameters;
        return OrderListScreen(initialQuery: query);
      },
    ),
    GoRoute(
      path: '/orders/create',
      builder: (context, state) => const OrderCreateScreen(),
    ),
    GoRoute(
      path: '/orders/:id/edit',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.tryParse(idStr);
        if (id == null) {
          return NotFoundScreen(location: state.uri.toString());
        }
        return OrderEditScreen(id: id);
      },
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.tryParse(idStr);
        if (id == null) {
          return NotFoundScreen(location: state.uri.toString());
        }
        return OrderDetailScreen(id: id);
      },
    ),
  ],
  errorBuilder: (context, state) => NotFoundScreen(
    location: state.uri.toString(),
  ),
);
