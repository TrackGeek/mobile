import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app/api_config.dart';
import 'app/server_config.dart';
import 'app/trackgeek_app.dart';
import 'controllers/session_controller.dart';
import 'l10n/l10n_context.dart';
import 'l10n/trackgeek_localizations.dart';
import 'services/activity_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/comment_service.dart';
import 'services/external_sign_in.dart';
import 'services/favorite_service.dart';
import 'services/game_service.dart';
import 'services/list_service.dart';
import 'services/media_detail_service.dart';
import 'services/notification_alerts.dart';
import 'services/notification_service.dart';
import 'services/person_service.dart';
import 'services/progress_service.dart';
import 'services/review_service.dart';
import 'services/search_service.dart';
import 'services/settings_service.dart';
import 'services/genre_service.dart';
import 'services/shop_service.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final l10n = await TrackGeekLocalizations.load(
    WidgetsBinding.instance.platformDispatcher.locale,
  );
  final client = http.Client();
  final api = ApiClient(
    client: client,
    config: ApiConfig(
      baseUrl: const String.fromEnvironment(
        'TRACKGEEK_API_URL',
        defaultValue: ServerConfig.defaultUrl,
      ),
    ),
  );
  final server = ServerConfig(api);
  await server.restore();
  const googleClientId = String.fromEnvironment('TRACKGEEK_GOOGLE_CLIENT_ID');
  final session = SessionController(
    AuthService(api),
    google: googleClientId.isEmpty
        ? null
        : GoogleSignInSource(serverClientId: googleClientId),
    passkeys: PlatformPasskeySource(),
  );
  await session.restore();
  if (session.loggedIn) unawaited(NotificationAlerts.enable());
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen(
    (uri) => unawaited(session.handleAuthDeepLink(uri)),
  );
  unawaited(
    appLinks.getInitialLink().then((uri) {
      if (uri != null) unawaited(session.handleAuthDeepLink(uri));
    }),
  );
  runApp(
    L10nScope(
      localizations: l10n,
      child: TrackGeekApp(
        search: SearchService(api),
        details: MediaDetailService(api),
        people: PersonService(api),
        favorites: FavoriteService(api),
        progress: ProgressService(api),
        activities: ActivityService(api),
        api: api,
        session: session,
        server: server,
        settings: SettingsService(api),
        users: UserService(api),
        reviews: ReviewService(api),
        lists: ListService(api),
        comments: CommentService(api),
        games: GameService(api),
        genres: GenreService(client: client),
        shop: ShopService(api),
        notifications: NotificationService(api),
      ),
    ),
  );
}
