import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/app/server_config.dart';
import 'package:trackgeek/components/feed/feed_tabs.dart';
import 'package:trackgeek/components/media/sliver_poster_grid.dart';
import 'package:trackgeek/components/user/media_card.dart';
import 'package:trackgeek/components/user/profile_tabs.dart';
import 'package:trackgeek/components/user/profile_header.dart';
import 'package:trackgeek/models/user_profile.dart';
import 'package:trackgeek/controllers/session_controller.dart';
import 'package:trackgeek/l10n/l10n_context.dart';
import 'package:trackgeek/models/feed_entry.dart';
import 'package:trackgeek/pages/auth_gate_page.dart';
import 'package:trackgeek/pages/search_page.dart';
import 'package:trackgeek/pages/settings_page.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/auth_service.dart';
import 'package:trackgeek/services/favorite_service.dart';
import 'package:trackgeek/services/genre_service.dart';
import 'package:trackgeek/services/media_detail_service.dart';
import 'package:trackgeek/services/person_service.dart';
import 'package:trackgeek/services/settings_service.dart';
import 'package:trackgeek/services/user_service.dart';
import 'package:trackgeek/styles/tg_theme.dart';

import 'controllers/fake_search_gateway.dart';
import 'helpers/test_l10n.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page,
    Size size, {
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    final l10n = await testL10n();
    await tester.pumpWidget(
      L10nScope(
        localizations: l10n,
        child: MaterialApp(
          theme: trackGeekTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('settings keeps unsaved profile draft across layout breakpoint', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    final session = SessionController(AuthService(api));
    addTearDown(session.dispose);
    await pumpPage(
      tester,
      SettingsPage(
        session: session,
        settings: SettingsService(api),
        auth: AuthService(api),
      ),
      const Size(1200, 900),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'Unsaved profile draft',
    );
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.text('Unsaved profile draft'), findsOneWidget);
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(find.text('Unsaved profile draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('profile header handles narrow viewport and large text', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await pumpPage(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ProfileHeader(
            user: UserProfile(
              id: 'u1',
              name: 'A very long profile display name',
              username: 'long_profile_username',
              profile: const UserProfileDetails(
                id: 'p1',
                title: 'A long custom profile title',
              ),
              createdAt: DateTime(2020),
              followers: 1000000,
              following: 1000000,
            ),
            isOwner: true,
          ),
        ),
      ),
      const Size(320, 480),
      scale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 640),
    const Size(720, 480),
    const Size(1440, 900),
  ]) {
    testWidgets('poster grid adapts at $size with large text', (tester) async {
      addTearDown(tester.view.reset);
      await pumpPage(
        tester,
        Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverPosterGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => MediaCard(
                      title:
                          'A long movie title that must remain readable $index',
                      image: '',
                    ),
                    childCount: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        size,
        scale: 2,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'tabs keep selection and semantics at narrow width with large text',
    (tester) async {
      addTearDown(tester.view.reset);
      FeedKind? selected;
      await pumpPage(
        tester,
        Scaffold(
          body: Column(
            children: [
              FeedTabs(
                active: FeedKind.global,
                onChanged: (value) => selected = value,
              ),
              ProfileTabs(
                tabs: const [
                  ('overview', 'Overview', null),
                  ('activity', 'Activity with a long name', '12'),
                ],
                active: 'overview',
                onSelect: (_) {},
              ),
            ],
          ),
        ),
        const Size(320, 640),
        scale: 2,
      );
      await tester.tap(find.byType(FeedTabs).first);
      expect(tester.takeException(), isNull);
      expect(selected, isNotNull);
    },
  );

  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets(
      'main pages fit $size and search still loads next page on scroll',
      (tester) async {
        addTearDown(tester.view.reset);
        final api = ApiClient(
          config: ApiConfig(baseUrl: 'https://api.example.test'),
          client: MockClient((_) async => http.Response('{}', 200)),
        );
        final session = SessionController(AuthService(api));
        addTearDown(session.dispose);
        await pumpPage(
          tester,
          AuthGatePage(session: session, server: ServerConfig(api)),
          size,
          scale: 1.4,
        );
        await pumpPage(
          tester,
          SettingsPage(
            session: session,
            settings: SettingsService(api),
            auth: AuthService(api),
          ),
          size,
          scale: 1.4,
        );
        final search = FakeSearchGateway(pages: 2, itemsPerPage: 30);
        await pumpPage(
          tester,
          SearchPage(
            search: search,
            details: MediaDetailService(api),
            people: PersonService(api),
            favorites: FavoriteService(api),
            session: session,
            users: UserService(api),
            genres: GenreService(
              client: MockClient((_) async => http.Response('{}', 200)),
            ),
            api: api,
          ),
          size,
          scale: 1.4,
        );
        expect(search.lastPage, 1);
        await tester.drag(find.byType(GridView), const Offset(0, -10000));
        await tester.pumpAndSettle();
        expect(search.lastPage, 2);
        await tester.enterText(find.byType(SearchBar), 'Interstellar');
        await tester.pump(const Duration(milliseconds: 650));
        await tester.pumpAndSettle();
        expect(search.lastQuery, 'Interstellar');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
