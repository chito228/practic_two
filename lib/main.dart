import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'repositories/client_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/in_memory_client_repository.dart';
import 'repositories/in_memory_order_repository.dart';
import 'state/client_list_notifier.dart';
import 'state/order_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<ClientRepository>(create: (_) => InMemoryClientRepository()),
        Provider<OrderRepository>(create: (_) => InMemoryOrderRepository()),
        ChangeNotifierProvider(
          create: (context) =>
              ClientListNotifier(context.read<ClientRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              OrderListNotifier(context.read<OrderRepository>())..load(),
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
