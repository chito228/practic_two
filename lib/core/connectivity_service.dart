import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Сервис мониторинга соединения с сервером.
///
/// Периодически пингует `/api/health` PocketBase. Когда состояние
/// меняется (было offline → стало online), вызывает [onReconnect].
/// UI подписывается через [ChangeNotifier] и показывает баннер.
class ConnectivityService extends ChangeNotifier {
  final Dio _dio;

  /// Интервал проверки в нормальном состоянии.
  final Duration interval;

  /// Вызывается при переходе offline → online.
  /// Сюда обычно вешают `notifier.load()` всех экранов.
  final VoidCallback? onReconnect;

  Timer? _timer;
  bool _isOnline = true;
  bool _isChecking = false;
  DateTime? _lastCheckAt;

  ConnectivityService(
    this._dio, {
    this.interval = const Duration(seconds: 5),
    this.onReconnect,
  });

  bool get isOnline => _isOnline;
  DateTime? get lastCheckAt => _lastCheckAt;

  void start() {
    _timer?.cancel();
    _check(); // первый пинг сразу
    _timer = Timer.periodic(interval, (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Разовый пинг. Можно дёрнуть вручную из UI.
  Future<bool> ping() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/health',
        options: Options(
          // Пинг не должен висеть долго.
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          // Не считаем 4xx/5xx «офлайном» — сервер доступен.
          validateStatus: (_) => true,
        ),
      );
      final ok = (response.statusCode ?? 0) < 500;
      _updateState(ok);
      return ok;
    } catch (_) {
      _updateState(false);
      return false;
    } finally {
      _lastCheckAt = DateTime.now();
    }
  }

  Future<void> _check() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      await ping();
    } finally {
      _isChecking = false;
    }
  }

  void _updateState(bool online) {
    if (_isOnline == online) return;
    final wasOffline = !_isOnline;
    _isOnline = online;
    notifyListeners();

    // Переход offline → online: дёргаем колбэк.
    if (online && wasOffline) {
      onReconnect?.call();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
