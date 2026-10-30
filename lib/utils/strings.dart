extension StringX on String? {
  bool get isUsable {
    return this != null && this!.isNotEmpty && this != 'null';
  }

  String orPlaceholder([String placeholder = '-']) {
    if (!isUsable) return placeholder;

    return this!;
  }
}
