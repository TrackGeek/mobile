import 'dart:ui';

import 'package:trackgeek/l10n/trackgeek_localizations.dart';

Future<TrackGeekLocalizations> testL10n() =>
    TrackGeekLocalizations.load(const Locale('en', 'US'), read: _read);

Future<String> _read(String path) async {
  if (!path.contains('en-US')) throw Exception('missing');
  if (path.endsWith('common.json')) {
    return '''
    {
      "search": "Search",
      "settings": "Settings",
      "profile": "Profile",
      "viewDetails": "View Details",
      "noResults": "No results found.",
      "noResultsDescription": "Try adjusting your search or filters.",
      "tryAgain": "Try again",
      "tryAgainLater": "Please try again in a moment.",
      "internalError": "Something went wrong.",
      "types": {
        "movie": "Movie", "tv": "TV Show", "game": "Game",
        "anime": "Anime", "manga": "Manga", "book": "Book",
        "cast": "Cast",
        "movie_other": "Movies", "tv_other": "TV Shows", "game_other": "Games",
        "anime_other": "Animes", "manga_other": "Mangas", "book_other": "Books"
      },
      "languages": {"enUS": "English"},
      "name": "Name",
      "password": "Password",
      "notifications": "Notifications",
      "loading": "Loading...",
      "cancel": "Cancel",
      "delete": "Delete",
      "saveChanges": "Save changes",
      "somethingWentWrong": "Something went wrong."
    }
    ''';
  }
  if (path.endsWith('settings.json')) {
    return '''
    {
      "tabs": {
        "appearance": "Appearance",
        "preferences": "Preferences",
        "security": "Security",
        "connections": "Connections",
        "account": "Account"
      },
      "watchLinks": {"title": "Watch Links"},
      "connections": {"description": "Manage linked applications."},
      "deleteAccount": {"description": "Delete your account."},
      "navigation": {
        "description": "Manage your profile, preferences and account.",
        "section": "Choose a settings section",
        "groups": {"personal": "Your profile", "application": "Application", "account": "Your account"},
        "descriptions": {"profile": "Update your profile.", "appearance": "Customize.", "preferences": "Preferences.", "watchLinks": "Watch links.", "security": "Security."}
      },
      "profile": {"title": "Profile", "description": "Update your profile."}
    }
    ''';
  }
  if (path.endsWith('notifications.json')) {
    return '''
    {"preferences": {"description": "Choose what you are notified about."}}
    ''';
  }
  if (path.endsWith('auth.json')) {
    return '''
    {
      "login": "Login",
      "register": "Register",
      "emailAddress": "Email Address",
      "logout": "Logout",
      "failedToLogin": "Failed to login. Please try again.",
      "welcome": {"description": "Please login to continue using the app."},
      "twoFactor": {"title": "Two-factor authentication", "description": "Enter the code.", "verify": "Verify"},
      "or": "or",
      "magicLink": "Magic Link",
      "sendMagicLink": "Send magic link",
      "magicLinkSent": "Check your inbox.",
      "passkey": "Passkey",
      "passkeyDescription": "Use a passkey to sign in.",
      "loginWithPasskey": "Sign in with passkey",
      "providers": {
        "discord": "Discord", "github": "Github", "google": "Google",
        "kick": "Kick", "microsoft": "Microsoft", "notion": "Notion",
        "slack": "Slack", "spotify": "Spotify", "twitter": "X"
      }
    }
    ''';
  }
  if (path.endsWith('app.json')) {
    return '''
    {
      "tabs": {"home": "Home", "search": "Search", "settings": "Settings"},
      "webOnly": {"title": "Only on the website", "description": "Web only.", "import": "Import", "oauthClients": "OAuth2", "addData": "Add data"},
      "server": {"default": "Default (TrackGeek)", "custom": "Custom instance", "url": "Instance URL", "invalid": "Invalid server URL"},
      "auth": {"password": "Password"},
      "library": "Library",
      "filters": {"apply": "Apply", "direction": "Direction"}
    }
    ''';
  }
  return '{}';
}
