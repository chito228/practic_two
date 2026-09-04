import 'package:flutter/material.dart';

class ResponsiveList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item) cardBuilder;
  final Widget Function(List<T> items) tableBuilder;
  final double breakpoint;

  const ResponsiveList({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.tableBuilder,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpoint) {
      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => cardBuilder(items[index]),
      );
    } else {
      return tableBuilder(items);
    }
  }
}
