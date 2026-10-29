class WatchProvider {
  const WatchProvider({required this.id, required this.name, this.logoUrl});

  factory WatchProvider.fromJson(Map<String, dynamic> json) => WatchProvider(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    logoUrl: json['logoUrl'] as String?,
  );

  final int id;
  final String name;
  final String? logoUrl;
}

const watchProviderOffers = ['flatrate', 'free', 'ads', 'rent', 'buy'];

class WatchProviders {
  const WatchProviders({
    required this.region,
    required this.availableRegions,
    required this.offers,
    this.link,
  });

  factory WatchProviders.fromJson(Map<String, dynamic> json) => WatchProviders(
    region: json['region'] as String? ?? '',
    availableRegions: [
      for (final r in json['availableRegions'] as List? ?? const []) '$r',
    ],
    offers: {
      for (final offer in watchProviderOffers)
        offer: [
          for (final p in json[offer] as List? ?? const [])
            if (p is Map<String, dynamic>) WatchProvider.fromJson(p),
        ],
    },
    link: json['link'] as String?,
  );

  final String region;
  final List<String> availableRegions;
  final Map<String, List<WatchProvider>> offers;
  final String? link;

  List<WatchProvider> offer(String key) => offers[key] ?? const [];
}

class WatchProviderRegion {
  const WatchProviderRegion({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  factory WatchProviderRegion.fromJson(Map<String, dynamic> json) =>
      WatchProviderRegion(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nativeName: json['nativeName'] as String? ?? '',
      );

  final String code;
  final String name;
  final String nativeName;
}
