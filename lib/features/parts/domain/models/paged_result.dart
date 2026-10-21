/// Generic wrapper for paginated result sets.
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int offset;
  final int limit;

  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.offset,
    required this.limit,
  });

  /// True if there are remaining items to fetch beyond this page.
  bool get hasMore => offset + items.length < totalCount;
}
