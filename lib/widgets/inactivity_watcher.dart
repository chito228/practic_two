import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Отслеживает неактивность пользователя.
///
/// Логика:
/// - При любом действии (клик, движение мыши, клавиша, скролл) — сброс таймера.
/// - Через (timeout - warningBefore) — показываем диалог предупреждения.
/// - Через timeout после последнего действия — вызываем onTimeout.
/// - Если пользователь нажал «Продолжить» — таймер сбрасывается.
///
/// Клавиатуру слушаем через HardwareKeyboard, потому что
/// KeyboardListener не работает, если его FocusNode не в фокусе.
/// Обёртка над всем приложением фокуса не имеет.
class InactivityWatcher extends StatefulWidget {
  /// Полный тайм-аут неактивности.
  final Duration timeout;

  /// За сколько до выхода показывать предупреждение.
  final Duration warningBefore;

  /// Что делать при истечении тайм-аута (обычно logout + go('/login')).
  final VoidCallback onTimeout;

  /// Что показать пользователю в диалоге предупреждения.
  final String warningMessage;

  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    this.warningBefore = const Duration(seconds: 30),
    required this.onTimeout,
    this.warningMessage =
        'Вы будете отключены через 30 секунд из-за неактивности.',
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timeoutTimer;
  Timer? _warningTimer;
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  /// false означает «событие не обработано, передайте его дальше».
  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    if (!mounted) return;

    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
    _warningShown = false;

    final warningAfter = widget.timeout - widget.warningBefore;

    // Таймер предупреждения (срабатывает раньше).
    if (warningAfter > Duration.zero) {
      _warningTimer = Timer(warningAfter, () {
        if (!mounted) return;
        _showWarning();
      });
    }

    // Таймер выхода.
    _timeoutTimer = Timer(widget.timeout, () {
      if (!mounted) return;
      widget.onTimeout();
    });
  }

  Future<void> _showWarning() async {
    if (_warningShown || !mounted) return;
    _warningShown = true;

    final seconds = widget.warningBefore.inSeconds;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Неактивность'),
        content: Text(
          widget.warningMessage.replaceAll('30', seconds.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Продолжить работу'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Выйти сейчас'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Пользователь вернулся — сбрасываем таймеры.
      _restart();
    } else {
      // Выход сейчас или диалог закрылся.
      widget.onTimeout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Перехват без поглощения: событие идёт дальше к виджетам.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}
