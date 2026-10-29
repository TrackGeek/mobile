class WatchLink {
  const WatchLink({
    required this.id,
    required this.label,
    required this.url,
    required this.contentTypes,
    required this.enabled,
    required this.position,
  });

  factory WatchLink.fromJson(Map<String, dynamic> json) => WatchLink(
    id: json['id'] as String,
    label: json['label'] as String? ?? '',
    url: json['url'] as String? ?? '',
    contentTypes: [
      for (final type in json['contentTypes'] as List? ?? const []) '$type',
    ],
    enabled: json['enabled'] as bool? ?? true,
    position: json['position'] as int? ?? 0,
  );

  final String id;
  final String label;
  final String url;
  final List<String> contentTypes;
  final bool enabled;
  final int position;
}
