enum CosmeticKind {
  profileColor('ProfileColor'),
  avatarFrame('AvatarFrame'),
  profileTitle('ProfileTitle'),
  bannerEffect('BannerEffect');

  const CosmeticKind(this.apiName);

  final String apiName;
}

class CosmeticUnlock {
  const CosmeticUnlock({required this.type, this.value, this.key, this.price});

  factory CosmeticUnlock.fromJson(Map<String, dynamic> json) => CosmeticUnlock(
    type: json['type'] as String? ?? 'default',
    value: json['value'] as int?,
    key: json['key'] as String?,
    price: json['price'] as int?,
  );

  final String type;
  final int? value;
  final String? key;
  final int? price;
}

class Cosmetic {
  const Cosmetic({
    required this.key,
    required this.value,
    required this.unlock,
    required this.unlocked,
    required this.owned,
    required this.equipped,
  });

  factory Cosmetic.fromJson(Map<String, dynamic> json) => Cosmetic(
    key: json['key'] as String? ?? '',
    value: json['value'] as String? ?? '',
    unlock: CosmeticUnlock.fromJson(
      json['unlock'] is Map<String, dynamic>
          ? json['unlock'] as Map<String, dynamic>
          : const {},
    ),
    unlocked: json['unlocked'] as bool? ?? false,
    owned: json['owned'] as bool? ?? false,
    equipped: json['equipped'] as bool? ?? false,
  );

  final String key;
  final String value;
  final CosmeticUnlock unlock;
  final bool unlocked;
  final bool owned;
  final bool equipped;
}

class CosmeticsBundle {
  const CosmeticsBundle({
    required this.profileColors,
    required this.avatarFrames,
    required this.profileTitles,
    required this.bannerEffects,
  });

  factory CosmeticsBundle.fromJson(Map<String, dynamic> json) {
    List<Cosmetic> list(String key) => [
      for (final item in json[key] as List? ?? const [])
        if (item is Map<String, dynamic>) Cosmetic.fromJson(item),
    ];
    return CosmeticsBundle(
      profileColors: list('profileColors'),
      avatarFrames: list('avatarFrames'),
      profileTitles: list('profileTitles'),
      bannerEffects: list('bannerEffects'),
    );
  }

  List<Cosmetic> itemsFor(CosmeticKind kind) => switch (kind) {
    CosmeticKind.profileColor => profileColors,
    CosmeticKind.avatarFrame => avatarFrames,
    CosmeticKind.profileTitle => profileTitles,
    CosmeticKind.bannerEffect => bannerEffects,
  };

  final List<Cosmetic> profileColors;
  final List<Cosmetic> avatarFrames;
  final List<Cosmetic> profileTitles;
  final List<Cosmetic> bannerEffects;
}
