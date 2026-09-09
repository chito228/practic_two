import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final void Function(int page) onPageChanged;
  final void Function(int size) onSizeChanged;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (totalPages > 1) ...[
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
                  tooltip: 'Первая страница',
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                  tooltip: 'Предыдущая страница',
                ),
                Text(
                  '$currentPage / $totalPages',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                  tooltip: 'Следующая страница',
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
                  tooltip: 'Последняя страница',
                ),
              ] else ...[
                const SizedBox(height: 48),
              ],
            ],
          ),
          Row(
            children: [
              const Text('Записей: '),
              DropdownButton<int>(
                value: pageSize,
                items: const [10, 25, 50]
                    .map((size) => DropdownMenuItem(
                          value: size,
                          child: Text(size.toString()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onSizeChanged(value);
                },
              ),
              const SizedBox(width: 16),
              Text('Всего: $totalItems'),
            ],
          ),
        ],
      ),
    );
  }
}
