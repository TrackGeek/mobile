import '../models/api_exception.dart';
import '../models/cosmetic.dart';
import '../models/wallet.dart';
import 'api_client.dart';

class ShopPurchase {
  const ShopPurchase({required this.wallet, required this.cosmetic});

  final Wallet wallet;
  final Cosmetic cosmetic;
}

class ShopService {
  const ShopService(this._api);

  final ApiClient _api;

  Future<Wallet> wallet() async {
    final res = await _api.requestJson('GET', 'coins/me');
    final wallet = res.json?['wallet'];
    if (wallet is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return Wallet.fromJson(wallet);
  }

  Future<CosmeticsBundle> cosmetics() async {
    final res = await _api.requestJson('GET', 'cosmetics');
    final json = res.json;
    if (json == null) {
      return const CosmeticsBundle(
        profileColors: [],
        avatarFrames: [],
        profileTitles: [],
        bannerEffects: [],
      );
    }
    return CosmeticsBundle.fromJson(json);
  }

  Future<ShopPurchase> purchaseCosmetic(CosmeticKind kind, String key) async {
    final res = await _api.requestJson(
      'POST',
      'cosmetics/purchase',
      body: {'type': kind.apiName, 'key': key},
    );
    final json = res.json;
    final wallet = json?['wallet'];
    final cosmetic = json?['cosmetic'];
    if (wallet is! Map<String, dynamic> || cosmetic is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return ShopPurchase(
      wallet: Wallet.fromJson(wallet),
      cosmetic: Cosmetic.fromJson(cosmetic),
    );
  }
}
