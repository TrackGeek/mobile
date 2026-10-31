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
- API dates in `Text`: never show raw ISO (`2016-07-24`) or `substring`; use `formatLongDate(value, L10nScope.of(context).language) ?? raw` (`lib/utils/dates.dart`) and `await ensureDateLocale(language)` before first render (`Future.wait` in a `FutureBuilder`, `_load()`, or `didChangeDependencies`). Models stay raw/locale-free; format at render site. Skip API-preformatted ranges and bare years.
- Counts ("how much"): never interpolate raw ints (`'$n'`); use `n.humanizedCount()` (`lib/utils/numbers.dart`, locale via `numberLocale` set by `TrackGeekLocalizations`). Skip "which one" values: indexes, ranks, IDs, durations, percents, 0-10 scores. Plural `context.t` keys: pass `{'count': n, 'formattedCount': n.humanizedCount()}` and use `{{formattedCount}}` in en-US JSON; keep `count` as an int so plural selection works.
- Keyboard action key: set `textInputAction` on every single-line field. Non-last field in multi-field form `.next`; last single-line field `.done` + `onFieldSubmitted: (_) => _submit()` (same handler as the button; extract inline button body into `_submit()` if needed). Search fields `.search`. Fields that already submit themselves (inline add, commit on edit) `.done`. Multiline (`maxLines` >= 2): never set action or submit (return key must insert newline). Lone single-purpose fields outside multi-field forms: leave default.
- Custom horizontal tab/chip selectors (`ListView`/`SingleChildScrollView` + `ChoiceChip`/`InkWell`; real `TabBar` already does it): keep selected item visible. One `GlobalKey` per item (`_keys.putIfAbsent(id, GlobalKey.new)`) on item widget; `Scrollable.ensureVisible(ctx, alignment: 0.5, duration: 200ms, curve: Curves.easeInOut)` after selection change and once in `initState` post-frame (`if (mounted)`). Selection driven by external listenable: call inside `addPostFrameCallback`. Stateless selector (e.g. `ProfileTabs`) → `StatefulWidget`, scroll in `didUpdateWidget` when active changes.
- Bottom inset of vertical scrollables (lists, grids, slivers, sheet bodies): never wrap in `SafeArea`; use `BottomPadding.of(context, minimum: <old bottom>)` (`lib/components/layout/bottom_padding.dart`, uses `MediaQuery.viewPaddingOf(context).bottom`, default minimum 16). Drop `const` on that padding. Plain constant → `.copyWith(bottom: BottomPadding.of(context))`. Keyboard-aware sheets keep `viewInsets.bottom + BottomPadding.of(context)`. Skip mid-scroll slivers.
- Horizontal lists must reach screen/card edges: do not pad the parent around them (clips items mid-scroll). Parent `0` horizontal padding; give each horizontal list `padding: const EdgeInsets.symmetric(horizontal: 16)` (`SingleChildScrollView` has `padding` too) and wrap non-scrolling siblings in `Padding(horizontal: 16)`. Cards: `UserCard(bleedChild: true)` and pad inner children individually; inset must match card's own (14 in `relations_view.dart`). Keep top/bottom values.
- Autofocus: `autofocus: true` only when the field is the sole input of the surface (single-field dialog/sheet, e.g. delete-account username, media picker). Never when field shares screen with other controls (auth 2FA, TOTP, multi-field forms, pickers with lists): keyboard hides alternatives.
