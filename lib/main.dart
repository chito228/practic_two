import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'core/api_client.dart';
import 'core/auth_api.dart';
import 'core/reference_cache.dart';
import 'router.dart';

import 'repositories/client_repository.dart';
import 'repositories/cargo_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/route_repository.dart';
import 'repositories/vehicle_repository.dart';

import 'repositories/api/api_client_repository.dart';
import 'repositories/api/api_cargo_repository.dart';
import 'repositories/api/api_order_repository.dart';
import 'repositories/api/api_route_repository.dart';
import 'repositories/api/api_vehicle_repository.dart';

import 'state/auth_notifier.dart';
import 'state/client_list_notifier.dart';
import 'state/order_list_notifier.dart';
import 'state/cargo_list_notifier.dart';
import 'state/route_list_notifier.dart';
import 'state/vehicle_list_notifier.dart';

import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  late final AuthNotifier authNotifier;

  final dio = buildDio(
    tokenProvider: () => authNotifier.accessToken,
    onRefresh: () => authNotifier.refreshTokens(),
    onUnauthorized: () => authNotifier.logout(),
  );

  final authApi = AuthApi(dio);

  authNotifier = AuthNotifier(prefs, authApi);
  await authNotifier.restore();

  buildRouter(authNotifier);

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        Provider<ReferenceCache>(create: (_) => ReferenceCache()),

        Provider<AuthApi>.value(value: authApi),
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),

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
      builder: (context, child) {
        // ВАЖНО: builder получает context уже ПОД MaterialApp,
        // то есть Navigator доступен. _AppWrapper окажется
        // внутри Navigator и showDialog сработает.
        return _AppWrapper(
          authNotifier: context.read<AuthNotifier>(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _AppWrapper extends StatefulWidget {
  final AuthNotifier authNotifier;
  final Widget child;
  final Duration warningBefore;

  const _AppWrapper({
    required this.authNotifier,
    required this.child,
    this.warningBefore = const Duration(seconds: 10),
  });

  @override
  State<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper> {
  Timer? _sessionTimer;
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    widget.authNotifier.addListener(_onAuthChanged);
    _startSessionTimer();
  }

  @override
  void dispose() {
    widget.authNotifier.removeListener(_onAuthChanged);
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!widget.authNotifier.isAuthenticated) {
      _sessionTimer?.cancel();
      _sessionTimer = null;
      _warningShown = false;
    } else {
      if (_sessionTimer == null || !_sessionTimer!.isActive) {
        _startSessionTimer();
      }
      final left = widget.authNotifier.sessionTimeLeft;
      if (left != null && left > widget.warningBefore) {
        _warningShown = false;
      }
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _warningShown = false;
    _sessionTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      final auth = widget.authNotifier;
      if (!auth.isAuthenticated) return;

      if (auth.isSessionExpired) {
        _forceLogout();
        return;
      }

      final left = auth.sessionTimeLeft;
      if (left != null && left <= widget.warningBefore && !_warningShown) {
        _showSessionWarning(left);
      }
    });
  }

  Future<void> _showSessionWarning(Duration left) async {
    _warningShown = true;
    if (!mounted) return;

    final seconds = left.inSeconds;
    // context здесь — из State, который находится ПОД MaterialApp,
    // значит Navigator доступен.
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Сессия скоро истечёт'),
        content: Text(
          'Через $seconds секунд вы будете отключены. Продолжить работу?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Продолжить работу'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      widget.authNotifier.extendSession();
    } else {
      await _forceLogout();
    }
  }

  Future<void> _forceLogout() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    await widget.authNotifier.logout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сессия истекла. Войдите снова.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InactivityWatcher(
      timeout: const Duration(minutes: 30),
      warningBefore: const Duration(seconds: 30),
      warningMessage:
          'Вы будете отключены через 30 секунд из-за неактивности. Продолжить работу?',
      onTimeout: () async {
        await widget.authNotifier.logout();
      },
      child: widget.child,
    );
  }
}
