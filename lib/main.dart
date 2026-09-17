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

// ─── Старые репозитории (не трогаем) ───────────────
import 'repositories/client_repository.dart';
import 'repositories/cargo_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/route_repository.dart';
import 'repositories/vehicle_repository.dart';

// ─── Старые API-репозитории (не трогаем) ───────────
import 'repositories/api/api_client_repository.dart';
import 'repositories/api/api_cargo_repository.dart';
import 'repositories/api/api_order_repository.dart';
import 'repositories/api/api_route_repository.dart';
import 'repositories/api/api_vehicle_repository.dart';

// ─── НОВЫЕ репозитории (AppUser) ───────────────────
import 'repositories/user_repository.dart';
import 'repositories/api/api_user_repository.dart';

// ─── НОВЫЕ репозитории (Warehouse) ─────────────────
import 'repositories/warehouse_repository.dart';
import 'repositories/api/api_warehouse_repository.dart';

// ─── НОВЫЕ репозитории (Task) ──────────────────────
import 'repositories/task_repository.dart';
import 'repositories/api/api_task_repository.dart';

// ─── НОВЫЕ репозитории (DriverLicense) ─────────────
import 'repositories/driver_license_repository.dart';
import 'repositories/api/api_driver_license_repository.dart';

// ─── Старые notifier'ы (не трогаем) ────────────────
import 'state/auth_notifier.dart';
import 'state/client_list_notifier.dart';
import 'state/order_list_notifier.dart';
import 'state/cargo_list_notifier.dart';
import 'state/route_list_notifier.dart';
import 'state/vehicle_list_notifier.dart';

// ─── НОВЫЕ notifier'ы ──────────────────────────────
import 'state/user_list_notifier.dart';
import 'state/warehouse_list_notifier.dart';
import 'state/task_list_notifier.dart';

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
        // ─── Базовые ───────────────────────────────
        Provider<Dio>.value(value: dio),
        Provider<ReferenceCache>(create: (_) => ReferenceCache()),
        Provider<AuthApi>.value(value: authApi),
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),

        // ─── Старые репозитории (не трогаем) ───────
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

        // ─── НОВЫЙ репозиторий (DriverLicense) ─────
        Provider<DriverLicenseRepository>(
          create: (context) =>
              ApiDriverLicenseRepository(context.read<Dio>()),
        ),

        // ─── Старые notifier'ы (не трогаем) ────────
        ChangeNotifierProvider(
          create: (context) =>
              ClientListNotifier(context.read<ClientRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              OrderListNotifier(context.read<OrderRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CargoListNotifier(context.read<CargoRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              RouteListNotifier(context.read<RouteRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              VehicleListNotifier(context.read<VehicleRepository>())..load(),
        ),

        // ─── НОВЫЕ репозитории ─────────────────────
        Provider<UserRepository>(
          create: (context) => ApiUserRepository(context.read<AuthApi>()),
        ),
        Provider<WarehouseRepository>(
          create: (context) => ApiWarehouseRepository(context.read<Dio>()),
        ),
        Provider<TaskRepository>(
          create: (context) => ApiTaskRepository(context.read<Dio>()),
        ),

        // ─── НОВЫЕ notifier'ы ──────────────────────
        ChangeNotifierProvider(
          create: (context) =>
              UserListNotifier(context.read<UserRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              WarehouseListNotifier(context.read<WarehouseRepository>())
                ..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TaskListNotifier(context.read<TaskRepository>())..load(),
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
  Timer? _connectivityTimer;
  bool _warningShown = false;

  /// Последнее известное состояние связи с сервером.
  /// true — сервер отвечает, false — нет.
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    widget.authNotifier.addListener(_onAuthChanged);
    _startSessionTimer();
    _startConnectivityTimer();
  }

  @override
  void dispose() {
    widget.authNotifier.removeListener(_onAuthChanged);
    _sessionTimer?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Сессия
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // Связь с сервером: пинг + авто-перезагрузка
  // ─────────────────────────────────────────────

  void _startConnectivityTimer() {
    _connectivityTimer?.cancel();
    _checkConnectivity(); // первый пинг сразу
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    final dio = context.read<Dio>();
    bool online;
    try {
      final response = await dio.get<dynamic>(
        '/api/health',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          // 4xx/5xx не считаем офлайном: сервер ответил — он доступен.
          validateStatus: (_) => true,
        ),
      );
      online = (response.statusCode ?? 0) < 500;
    } catch (_) {
      online = false;
    }

    if (!mounted) return;

    final wasOffline = !_isOnline;
    if (_isOnline != online) {
      setState(() => _isOnline = online);
    }

    // Переход offline → online: авто-перезагрузка всех списков.
    if (online && wasOffline) {
      _reloadAll();
    }
  }

  Future<void> _reloadAll() async {
    if (!mounted) return;
    try {
      context.read<ClientListNotifier>().load();
      context.read<OrderListNotifier>().load();
      context.read<CargoListNotifier>().load();
      context.read<RouteListNotifier>().load();
      context.read<VehicleListNotifier>().load();
      context.read<UserListNotifier>().load();
      context.read<WarehouseListNotifier>().load();
      context.read<TaskListNotifier>().load();
    } catch (_) {
      // Игнорируем: если какой-то нотифаер ещё не создан, ничего страшного.
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
      child: Column(
        children: [
          // Баннер «Нет соединения» поверх любого экрана.
          if (!_isOnline)
            Material(
              color: Colors.red.shade700,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Нет соединения с сервером. Пытаемся восстановить…',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: _checkConnectivity,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Проверить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
