import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/components/user/profile_header.dart';
import 'package:trackgeek/controllers/session_controller.dart';
import 'package:trackgeek/l10n/l10n_context.dart';
import 'package:trackgeek/pages/profile_page.dart';
import 'package:trackgeek/services/activity_service.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/auth_service.dart';
import 'package:trackgeek/services/comment_service.dart';
import 'package:trackgeek/services/favorite_service.dart';
import 'package:trackgeek/services/game_service.dart';
import 'package:trackgeek/services/list_service.dart';
import 'package:trackgeek/services/media_detail_service.dart';
import 'package:trackgeek/services/person_service.dart';
import 'package:trackgeek/services/progress_service.dart';
import 'package:trackgeek/services/review_service.dart';
import 'package:trackgeek/services/user_service.dart';

import '../helpers/test_l10n.dart';

void main() {
  testWidgets('follow button leaves loading after a successful follow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      SessionController.tokenKey: 'token',
    });
    var following = false;
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        final path = request.url.path;
        if (path == '/auth/get-session') {
          return http.Response(
            jsonEncode({
              'user': {
                'id': 'u1',
                'name': 'Current user',
                'email': 'current@example.test',
                'username': 'current',
              },
            }),
            200,
          );
        }
        if (path == '/user/follow-status/ana') {
          return http.Response(
            jsonEncode({
              'followStatus': {'isFollowing': following, 'followsYou': false},
            }),
            200,
          );
        }
        if (path == '/user/follow/u2' && request.method == 'POST') {
          following = true;
          return http.Response('{}', 200);
        }
        if (path == '/user/username/ana') {
          return http.Response(
            jsonEncode({
              'user': {
                'id': 'u2',
                'name': 'Ana',
                'username': 'ana',
                'profile': {'id': 'p2'},
                'createdAt': '2026-01-01T00:00:00Z',
                '_count': {'followers': following ? 1 : 0, 'following': 0},
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );
    addTearDown(api.close);
    final session = SessionController(AuthService(api));
    addTearDown(session.dispose);
    await session.restore();
    final l10n = await testL10n();

    await tester.pumpWidget(
      L10nScope(
        localizations: l10n,
        child: MaterialApp(
          home: ProfilePage(
            session: session,
            users: UserService(api),
            progress: ProgressService(api),
            favorites: FavoriteService(api),
            reviews: ReviewService(api),
            lists: ListService(api),
            comments: CommentService(api),
            games: GameService(api),
            activities: ActivityService(api),
            details: MediaDetailService(api),
            people: PersonService(api),
            api: api,
            username: 'ana',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('user:follow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('user:follow'));
    await tester.pumpAndSettle();

    final header = tester.widget<ProfileHeader>(find.byType(ProfileHeader));
    expect(header.followBusy, isFalse);
    expect(header.isFollowing, isTrue);
    expect(following, isTrue);
  });
}
