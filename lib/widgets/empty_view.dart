import 'package:flutter/material.dart';

/// Единое отображение пустого результата.
class EmptyView extends StatelessWidget {
  final String? message;

  const EmptyView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message ?? 'Ничего не найдено.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
