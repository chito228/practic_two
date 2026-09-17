import 'package:flutter/material.dart';

/// Единое отображение ошибки: иконка, текст и кнопка «Повторить».
class ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final text = message ?? 'Не удалось загрузить данные.';
    final isNetwork = text.toLowerCase().contains('соединен') ||
        text.toLowerCase().contains('сервер') ||
        text.toLowerCase().contains('доступ');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNetwork ? Icons.cloud_off : Icons.error_outline,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
