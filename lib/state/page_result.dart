class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;

  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  factory PageResult.empty() {
    return const PageResult(
      items: [],
      page: 1,
      size: 0,
      total: 0,
    );
  }

  int get totalPages => size == 0 ? 0 : (total / size).ceil();
  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;
}
