# Agent Instructions

## Stack
- Flutter/Dart app (`pubspec.yaml`); `README.md` is stale (describes old Kotlin/Compose app) — ignore its stack/build steps.
- Deps: `flutter pub get`; add with `flutter pub add <pkg>`.

## Commands
| Task | Command |
|------|---------|
| Analyze file | `flutter analyze lib/path/to/file.dart` |
| Format file | `dart format lib/path/to/file.dart` |
| Test file | `flutter test test/path/to/file_test.dart` |
| All tests | `flutter test` |
| Run | `flutter run --dart-define=TRACKGEEK_API_URL=https://api.trackgeek.net` |

## Build Defines
- `TRACKGEEK_API_URL`: API base (default `ServerConfig.defaultUrl` in `lib/app/server_config.dart`); must be HTTPS (`lib/app/api_config.dart`).
- `TRACKGEEK_GOOGLE_CLIENT_ID`: Google sign-in; empty disables it.

## Layout
| Path | Purpose |
|------|---------|
| `lib/main.dart` | Wiring of `ApiClient`, services, `SessionController` |
| `lib/services/` | API calls via `ApiClient`; one service per domain |
| `lib/models/` | API DTOs |
| `lib/controllers/` | State via `ChangeNotifier` |
| `lib/pages/`, `lib/components/<area>/` | UI |
| `lib/styles/` | Theme (`tg_theme.dart`) and layout tokens (`tg_layout.dart`) |
| `lib/l10n/` | Custom JSON localization loader |
| `assets/i18n/<locale>/<ns>.json` | Translation strings |

## Key Conventions
- UI strings: use `context.t('ns.key')` (`lib/l10n/l10n_context.dart`); never hardcode text.
- New strings: add to `assets/i18n/en-US/` at minimum.
- New locale folder: also register it under `flutter.assets` in `pubspec.yaml`.
- Service tests mirror `lib/services/` in `test/services/`; widget tests needing l10n use `test/helpers/test_l10n.dart`.
- Reuse `lib/styles/` tokens instead of inline colors/spacing.
- Do not edit `build/`, `.dart_tool/`, or generated platform files.
- `flutter test` all-at-once may flake with `WebSocketException: Invalid WebSocket upgrade request` (env, not code); rerun with `-j 1` or per file.

## External References
| Need | File |
|------|------|
| PR guidelines | `.github/CONTRIBUTING.md` |
| Commit format | `.github/COMMIT_CONVENTION.md` |
| PR template | `.github/PULL_REQUEST_TEMPLATE.MD` |

## Commits
- Format: `type(Scope): subject` per `.github/COMMIT_CONVENTION.md`.

## UI Conventions
- Network images: use `SmoothImage` (`lib/components/media/smooth_image.dart`, wraps `image_fade`); never `Image.network`/`NetworkImage`. Exception: `zoomable_image.dart`. Avatars: `CircleAvatar` + `ClipOval(SmoothImage)`, no `backgroundImage`.
- Scrollbars: app-wide via `AlwaysScrollbarBehavior` in `MaterialApp.scrollBehavior`; do not add manual `Scrollbar` widgets (double-bar clash).
- Small non-scrolling modal sheets: `showSpringBottomSheet` (`lib/components/layout/spring_sheet.dart`). Scrollable/`isScrollControlled` sheets stay on `showModalBottomSheet`; never put a scrollable inside the spring sheet.
- API strings in `Text`: never `x ?? ''`; use `x.orPlaceholder()` / `x.isUsable` (`lib/utils/strings.dart`) so `null`, `""`, `"null"` show `-` or hide the widget. Parenthesize nullable chains: `(a?.b).orPlaceholder()`. Exception: AppBar titles while loading.
- Horizontal scrollables (`scrollDirection: Axis.horizontal`): wrap in `Edgy(axis: .horizontal, child: ...)` (`lib/components/layout/edgy.dart`) for edge fade; not for `PageView` carousels.
- Haptics: use `HapticsHelper` (`lib/utils/haptics.dart`), never `HapticFeedback`/`Haptics` directly. `light` tab/switch/like/favorite, `selection` list picks, `success`/`error` on submit and toast results, `heavy` account deletion. Pull-to-refresh: `TgRefreshIndicator` (`lib/components/layout/tg_refresh_indicator.dart`), never raw `RefreshIndicator`. Toast helpers take an `error` flag to pick haptic.
- Scrollables containing (or sitting under) a text field: set `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`. Skip scrollables with no field.
- Before any `showModalBottomSheet`/`showDialog`/`showDatePicker`/`showSpringBottomSheet` reachable while a field may hold focus: `FocusManager.instance.primaryFocus?.unfocus();`. Never `FocusScope.of(context).unfocus()`.
- Build errors: `ErrorWidget.builder` set in `main()` to `FriendlyErrorView` (`lib/components/layout/friendly_error_view.dart`); do not override it per-screen.
