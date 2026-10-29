import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/app/server_config.dart';
import 'package:trackgeek/app/trackgeek_app.dart';
import 'package:trackgeek/controllers/session_controller.dart';
import 'package:trackgeek/l10n/l10n_context.dart';
import 'package:trackgeek/pages/settings_page.dart';
import 'package:trackgeek/services/activity_service.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/auth_service.dart';
import 'package:trackgeek/services/comment_service.dart';
import 'package:trackgeek/services/favorite_service.dart';
import 'package:trackgeek/services/game_service.dart';
import 'package:trackgeek/services/list_service.dart';
import 'package:trackgeek/services/media_detail_service.dart';
import 'package:trackgeek/services/notification_service.dart';
import 'package:trackgeek/services/person_service.dart';
import 'package:trackgeek/services/progress_service.dart';
import 'package:trackgeek/services/review_service.dart';
import 'package:trackgeek/services/settings_service.dart';
import 'package:trackgeek/services/genre_service.dart';
import 'package:trackgeek/services/shop_service.dart';
import 'package:trackgeek/services/user_service.dart';

import 'controllers/fake_search_gateway.dart';
import 'helpers/test_l10n.dart';

ApiClient _api() => ApiClient(
  config: ApiConfig(baseUrl: 'https://api.example.test'),
  client: MockClient((_) async => http.Response('{}', 200)),
);

Widget _app() {
  final api = _api();
  return TrackGeekApp(
    search: FakeSearchGateway(),
    details: MediaDetailService(api),
    people: PersonService(api),
    favorites: FavoriteService(api),
    progress: ProgressService(api),
    activities: ActivityService(api),
    api: api,
    session: SessionController(AuthService(api))..restore(),
    server: ServerConfig(api),
    settings: SettingsService(api),
    users: UserService(api),
    reviews: ReviewService(api),
    lists: ListService(api),
    comments: CommentService(api),
    games: GameService(api),
    genres: GenreService(
      client: MockClient((_) async => http.Response('{}', 200)),
    ),
    shop: ShopService(api),
    notifications: NotificationService(api),
  );
}

Future<void> _scrollIntoTapRange(
  WidgetTester tester,
  Finder finder,
  Finder scrollable,
) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 120, scrollable: scrollable);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  while (tester.getCenter(finder).dy > 560) {
    await tester.drag(scrollable, const Offset(0, -100));
    await tester.pumpAndSettle();
  }
}

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('shows forced auth gate with server selector when logged out', (
    tester,
  ) async {
    final l10n = await testL10n();
    await tester.pumpWidget(L10nScope(localizations: l10n, child: _app()));
    await tester.pumpAndSettle();

    expect(find.text('TrackGeek'), findsWidgets);
    expect(find.text('Default (TrackGeek)'), findsOneWidget);
    expect(find.text('Custom instance'), findsOneWidget);
    final scrollable = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Login'),
      150,
      scrollable: scrollable,
    );
    expect(find.text('Login'), findsWidgets);
    var fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].autofillHints, contains(AutofillHints.username));
    expect(fields[1].autofillHints, contains(AutofillHints.password));
    expect(find.byType(AutofillGroup), findsOneWidget);

    await _scrollIntoTapRange(tester, find.text('Register'), scrollable);
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].autofillHints, contains(AutofillHints.name));
    expect(fields[1].autofillHints, contains(AutofillHints.email));
    expect(fields[2].autofillHints, contains(AutofillHints.newPassword));
  });

  testWidgets('auth gate shows social providers and method switcher', (
    tester,
  ) async {
    final l10n = await testL10n();
    await tester.pumpWidget(L10nScope(localizations: l10n, child: _app()));
    await tester.pumpAndSettle();

    for (final id in [
      'discord',
      'github',
      'google',
      'kick',
      'microsoft',
      'notion',
      'slack',
      'spotify',
      'twitter',
    ]) {
      expect(find.byKey(ValueKey('auth-provider-$id')), findsOneWidget);
    }

    final scrollable = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await _scrollIntoTapRange(tester, find.text('Magic Link'), scrollable);
    await tester.tap(find.text('Magic Link'));
    await tester.pumpAndSettle();
    await _scrollIntoTapRange(
      tester,
      find.widgetWithText(FilledButton, 'Send magic link'),
      scrollable,
    );
    expect(find.text('Send magic link'), findsOneWidget);

    await _scrollIntoTapRange(tester, find.text('Passkey'), scrollable);
    await tester.tap(find.text('Passkey'));
    await tester.pumpAndSettle();
    await _scrollIntoTapRange(
      tester,
      find.widgetWithText(FilledButton, 'Sign in with passkey'),
      scrollable,
    );
    expect(find.text('Sign in with passkey'), findsOneWidget);
  });

  testWidgets('settings show sections without import or OAuth2 connections', (
    tester,
  ) async {
    final l10n = await testL10n();
    final api = _api();
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      L10nScope(
        localizations: l10n,
        child: MaterialApp(
          home: SettingsPage(
            session: SessionController(AuthService(api))..restore(),
            settings: SettingsService(api),
            auth: AuthService(api),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Import'), findsNothing);
    expect(find.text('OAuth2'), findsNothing);
  });
}
