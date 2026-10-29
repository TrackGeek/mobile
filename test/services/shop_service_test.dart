import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/models/cosmetic.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/shop_service.dart';

void main() {
  final requests = <http.Request>[];

  ShopService service(Object? response, {int status = 200}) {
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response.bytes(utf8.encode(jsonEncode(response)), status);
      }),
    );
    addTearDown(api.close);
    return ShopService(api);
  }

  setUp(requests.clear);

  test('wallet reads balance from the envelope', () async {
    final wallet = await service({
      'wallet': {'balance': 420, 'lifetimeEarned': 900, 'lifetimeSpent': 480},
    }).wallet();
    expect(wallet.balance, 420);
    expect(wallet.lifetimeEarned, 900);
    expect(wallet.lifetimeSpent, 480);
    expect(requests.single.method, 'GET');
    expect(requests.single.url.path, '/coins/me');
  });

  test('wallet rejects malformed payloads', () async {
    for (final response in [
      <String, dynamic>{},
      {'wallet': 'coins'},
    ]) {
      await expectLater(
        service(response).wallet(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.invalidResponse,
          ),
        ),
      );
    }
  });

  test('cosmetics parses the catalog sections', () async {
    final bundle = await service({
      'profileColors': [
        {
          'key': 'dusk',
          'value': 'gradient:dusk',
          'unlock': {'type': 'purchase', 'price': 500},
          'unlocked': false,
          'owned': false,
          'equipped': false,
        },
      ],
      'avatarFrames': [
        {
          'key': 'gold_ring',
          'value': 'gold_ring',
          'unlock': {'type': 'level', 'value': 20},
          'unlocked': true,
          'owned': false,
          'equipped': false,
        },
      ],
      'profileTitles': [],
      'bannerEffects': [],
    }).cosmetics();
    expect(requests.single.url.path, '/cosmetics');
    expect(bundle.profileColors.single.key, 'dusk');
    expect(bundle.profileColors.single.unlock.price, 500);
    expect(bundle.itemsFor(CosmeticKind.avatarFrame).single.key, 'gold_ring');
    expect(bundle.itemsFor(CosmeticKind.profileTitle), isEmpty);
    expect(bundle.itemsFor(CosmeticKind.bannerEffect), isEmpty);
  });

  test('purchaseCosmetic posts type and key', () async {
    final purchase = await service({
      'wallet': {'balance': 300, 'lifetimeEarned': 900, 'lifetimeSpent': 600},
      'cosmetic': {
        'key': 'neon',
        'value': 'neon',
        'unlock': {'type': 'purchase', 'price': 200},
        'unlocked': true,
        'owned': true,
        'equipped': false,
      },
    }).purchaseCosmetic(CosmeticKind.avatarFrame, 'neon');
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/cosmetics/purchase');
    expect(jsonDecode(requests.single.body) as Map<String, dynamic>, {
      'type': 'AvatarFrame',
      'key': 'neon',
    });
    expect(purchase.wallet.balance, 300);
    expect(purchase.cosmetic.owned, isTrue);
    expect(purchase.cosmetic.key, 'neon');
  });

  test('purchaseCosmetic surfaces the API error code', () async {
    await expectLater(
      service({
        'code': 'INSUFFICIENT_BALANCE',
      }, status: 422).purchaseCosmetic(CosmeticKind.profileColor, 'prism'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.serverCode,
          'serverCode',
          'INSUFFICIENT_BALANCE',
        ),
      ),
    );
  });
}
