import 'package:flutter/material.dart';

import '../controllers/session_controller.dart';
import '../pages/auth_gate_page.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/comment_service.dart';
import '../services/favorite_service.dart';
import '../services/game_service.dart';
import '../services/list_service.dart';
import '../services/media_detail_service.dart';
import '../services/notification_service.dart';
import '../services/person_service.dart';
import '../services/progress_service.dart';
import '../services/review_service.dart';
import '../services/search_service.dart';
import '../services/settings_service.dart';
import '../services/genre_service.dart';
import '../services/shop_service.dart';
import '../services/user_service.dart';
import '../styles/tg_theme.dart';
import 'server_config.dart';
import 'trackgeek_shell.dart';

class TrackGeekApp extends StatelessWidget {
  const TrackGeekApp({
    super.key,
    required this.search,
    required this.details,
    required this.people,
    required this.favorites,
    required this.progress,
    required this.activities,
    required this.api,
    required this.session,
    required this.server,
    required this.settings,
    required this.users,
    required this.reviews,
    required this.lists,
    required this.comments,
    required this.games,
    required this.genres,
    required this.shop,
    required this.notifications,
  });

  final SearchGateway search;
  final MediaDetailService details;
  final PersonService people;
  final FavoriteService favorites;
  final ProgressService progress;
  final ActivityService activities;
  final ApiClient api;
  final SessionController session;
  final ServerConfig server;
  final SettingsService settings;
  final UserService users;
  final ReviewService reviews;
  final ListService lists;
  final CommentService comments;
  final GameService games;
  final GenreService genres;
  final ShopService shop;
  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackGeek',
      theme: trackGeekTheme(),
      home: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (session.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!session.loggedIn) {
            return AuthGatePage(session: session, server: server);
          }
          return TrackGeekShell(
            search: search,
            details: details,
            people: people,
            favorites: favorites,
            progress: progress,
            activities: activities,
            api: api,
            session: session,
            settings: settings,
            users: users,
            reviews: reviews,
            lists: lists,
            comments: comments,
            games: games,
            genres: genres,
            shop: shop,
            notifications: notifications,
          );
        },
      ),
    );
  }
}
