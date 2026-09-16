import 'package:flutter/material.dart';
import '../utils/breakpoints.dart';

class ResponsiveList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item) cardBuilder;
  final Widget Function(List<T> items) tableBuilder;
  final double twoColumnBreakpoint;
  final double tableBreakpoint;

  const ResponsiveList({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.tableBuilder,
    this.twoColumnBreakpoint = Breakpoints.tablet, // 768
    this.tableBreakpoint = Breakpoints.desktop,     // 1280
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < twoColumnBreakpoint) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, i) => cardBuilder(items[i]),
      );
    }

    if (width < tableBreakpoint) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.0,  // карточка выше — текст помещается
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => cardBuilder(items[i]),
      );
    }

    return tableBuilder(items);
  }
}
