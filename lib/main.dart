import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'core/api_client.dart';
import 'core/auth_session.dart';
import 'core/reference_cache.dart';
import 'router.dart';

// Интерфейсы репозиториев
import 'repositories/client_repository.dart';
import 'repositories/cargo_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/route_repository.dart';
import 'repositories/vehicle_repository.dart';

// Api-реализации (ПР4)
import 'repositories/api/api_client_repository.dart';
import 'repositories/api/api_cargo_repository.dart';
import 'repositories/api/api_order_repository.dart';
import 'repositories/api/api_route_repository.dart';
import 'repositories/api/api_vehicle_repository.dart';

// Нотифаеры
import 'state/client_list_notifier.dart';
import 'state/order_list_notifier.dart';
import 'state/cargo_list_notifier.dart';
import 'state/route_list_notifier.dart';
import 'state/vehicle_list_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final authSession = AuthSession();
  final dio = buildDio(authSession);

  // Пытаемся войти. Если сервер недоступен — не падаем,
  // а запускаем приложение: нотифаеры покажут ErrorView.
  try {
    await authSession.loginWith(
      dio,
      username: 'librarian',
      password: 'librarian123',
    );
  } catch (e) {
    debugPrint('Не удалось выполнить вход: $e');
  }

  await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        // ── Dio и сессия ─────────────────────────────────
        Provider<Dio>.value(value: dio),
        Provider<AuthSession>.value(value: authSession),

        // ── Кэш справочников ─────────────────────────────
        Provider<ReferenceCache>(create: (_) => ReferenceCache()),

        // ── Api-репозитории ──────────────────────────────
        Provider<ClientRepository>(
          create: (context) => ApiClientRepository(context.read<Dio>()),
        ),
        Provider<CargoRepository>(
          create: (context) => ApiCargoRepository(context.read<Dio>()),
        ),
        Provider<RouteRepository>(
          create: (context) => ApiRouteRepository(context.read<Dio>()),
        ),
        Provider<VehicleRepository>(
          create: (context) => ApiVehicleRepository(context.read<Dio>()),
        ),
        Provider<OrderRepository>(
          create: (context) => ApiOrderRepository(context.read<Dio>()),
        ),

        // ── Нотифаеры ────────────────────────────────────
        ChangeNotifierProvider(
          create: (context) => ClientListNotifier(
            context.read<ClientRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => OrderListNotifier(
            context.read<OrderRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => CargoListNotifier(
            context.read<CargoRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => RouteListNotifier(
            context.read<RouteRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => VehicleListNotifier(
            context.read<VehicleRepository>(),
          )..load(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Логистика',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
