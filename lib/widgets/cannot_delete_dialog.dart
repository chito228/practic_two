import 'package:flutter/material.dart';

/// Диалог «Нельзя удалить — есть связанные данные».
///
/// Минимальный набор: заголовок, текст, список связанных сущностей.
/// Всё одним размером, чёрным цветом. Кнопка «Понятно» без стилей.
Future<void> showCannotDeleteDialog(
  BuildContext context, {
  required String entityName,
  required List<String> blockers,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Нельзя удалить',
        style: TextStyle(color: Colors.black),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '«$entityName» используется в других записях:',
            style: const TextStyle(color: Colors.black),
          ),
          const SizedBox(height: 8),
          ...blockers.map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• $b',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Сначала удалите или измените эти записи, затем попробуйте снова.',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Понятно'),
        ),
      ],
    ),
  );
}
