class PaginatedPage<T> {
  PaginatedPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decodeItem,
  ) : total = json['total'] as int?,
      pages = json['pages'] as int?,
      inPage = json['inPage'] as int,
      itemsInPage = json['itemsInPage'] as int,
      itemsPerPage = json['itemsPerPage'] as int?,
      items = List.unmodifiable(
        (json['items'] as List).map(
          (item) => decodeItem(item as Map<String, dynamic>),
        ),
      ) {
    if ((pages != null && pages! < 0) ||
        inPage < 1 ||
        itemsInPage != items.length ||
        (total != null && total! < 0) ||
        (itemsPerPage != null && itemsPerPage! < 1)) {
      throw const FormatException('Invalid pagination');
    }
  }

  final int? total;
  final int? pages;
  final int inPage;
  final int itemsInPage;
  final int? itemsPerPage;
  final List<T> items;

  bool get hasNextPage {
    if (pages != null && inPage >= pages!) return false;
    if (itemsPerPage == null) return pages != null && inPage < pages!;
    return itemsInPage >= itemsPerPage!;
  }
}
