import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    int? sortColumnIndex;
    if (sortField != null) {
      sortColumnIndex =
          columns.indexWhere((col) => col.sortField == sortField);
      if (sortColumnIndex == -1) sortColumnIndex = null;
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            columns: [
              if (onToggleSelect != null)
                const DataColumn(
                  label: SizedBox(width: 40, child: Text('')),
                ),
              ...columns.map((col) {
                return DataColumn(
                  label: Text(
                    col.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                  numeric: col.numeric,
                  onSort: col.sortField != null && onSort != null
                      ? (_, _) => onSort!(col.sortField!)
                      : null,
                );
              }),
              if (actions != null)
                const DataColumn(
                  label: SizedBox(width: 80, child: Text('Действия')),
                ),
            ],
            rows: items.map((item) {
              final id = idOf(item);
              final isSelected = selected.contains(id);
              return DataRow(
                selected: isSelected,
                cells: [
                  if (onToggleSelect != null)
                    DataCell(
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggleSelect!(id),
                      ),
                    ),
                  ...columns.map((col) => DataCell(col.build(item))),
                  if (actions != null)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!(item),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
