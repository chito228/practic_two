import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'router.dart';
import 'repositories/persistent_client_repository.dart';
import 'repositories/persistent_order_repository.dart';
import 'repositories/persistent_cargo_repository.dart';
import 'repositories/persistent_route_repository.dart';
import 'repositories/persistent_vehicle_repository.dart';
import 'state/client_list_notifier.dart';
import 'state/order_list_notifier.dart';
import 'state/cargo_list_notifier.dart';
import 'state/route_list_notifier.dart';
import 'state/vehicle_list_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        // Репозитории
        Provider<PersistentClientRepository>(
          create: (_) => PersistentClientRepository(prefs, 'clients_v1'),
        ),
        Provider<PersistentOrderRepository>(
          create: (_) => PersistentOrderRepository(prefs, 'orders_v1'),
        ),
        Provider<PersistentCargoRepository>(
          create: (_) => PersistentCargoRepository(prefs, 'cargo_v1'),
        ),
        Provider<PersistentRouteRepository>(
          create: (_) => PersistentRouteRepository(prefs, 'routes_v1'),
        ),
        Provider<PersistentVehicleRepository>(
          create: (_) => PersistentVehicleRepository(prefs, 'vehicles_v1'),
        ),
        // Notifiers
        ChangeNotifierProvider(
          create: (context) => ClientListNotifier(
            context.read<PersistentClientRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => OrderListNotifier(
            context.read<PersistentOrderRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => CargoListNotifier(
            context.read<PersistentCargoRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => RouteListNotifier(
            context.read<PersistentRouteRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => VehicleListNotifier(
            context.read<PersistentVehicleRepository>(),
          )..load(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
