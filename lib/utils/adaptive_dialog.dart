import 'package:flutter/material.dart';

/// Показывает диалог, ограниченный по ширине.
/// На широких экранах диалог не растягивается на весь монитор.
Future<T?> showAdaptiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: builder(context),
        ),
      );
    },
  );
}
