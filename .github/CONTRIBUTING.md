<div align="center">
    <img src="https://github.com/TrackGeek.png?size=2048" width="128px" style="max-width:100%;">
    <h3 style="font-size: 2rem; margin-bottom: 0">PR Guidelines</h3>
    <h4 style="margin-top: 0">Revision 1.3</h4>
    <br />
</div>

# Guidelines

When publishing a PR to this GitHub, we require you to follow a set of guidelines. To some, these strict rules may seem
harsh. However, the implementation of these rulesets will keep us and the users from running into any issues.

# Setup

TrackGeek Mobile is a [Flutter](https://flutter.dev) app (Android and iOS).

```bash
flutter pub get
flutter run --dart-define=TRACKGEEK_API_URL=https://api.trackgeek.net
```

Optional build defines: `TRACKGEEK_GOOGLE_CLIENT_ID` (Google sign-in), `DATAXAMAS_API_KEY` and `DATAXAMAS_BASE_URL` (
analytics). See `AGENTS.md` for details.

# Creation

> The code you write **must** be _well-written_ and **must** be _readable_ and all strings must be grammatically
> correct.

> Each PR follows a strict linting ruleset which will be checked during the review process. The rules come from
> `flutter_lints` (see `analysis_options.yaml`).

Before opening a PR, run:

```bash
dart format lib test
flutter analyze
flutter test -j 1
```

Here is a list of rules you must follow when writing your code:

- Follow the project layout: services in `lib/services/`, DTOs in `lib/models/`, state in `lib/controllers/`, UI in
  `lib/pages/` and `lib/components/<area>/`, theme and layout tokens in `lib/styles/`.
- Reuse the tokens in `lib/styles/` instead of inline colors and spacing.
- All UI strings **must** use `context.t('ns.key')`. Never hardcode text.
- It is **forbidden** to code without adding support to its primary language: every new string **must** be added to
  `assets/i18n/en-US/` at minimum (for e.g., a settings page coded with support only for Portuguese and Japanese, but not
  English itself). New locale folders must also be registered under `flutter.assets` in `pubspec.yaml`.
- Network images **must** use `SmoothImage`, never `Image.network`.
- Haptics **must** go through `HapticsHelper`, never `HapticFeedback` directly.
- Every pushed `MaterialPageRoute` **must** set `settings: RouteSettings(name: '/screen')`.
- Do not edit `build/`, `.dart_tool/` or generated platform files.
- All assets **must** have a good resolution. Prefer SVG for icons and illustrations; for raster images provide
  resolutions that look sharp on high-density screens (up to 3x).
- Features which contain some explicit content should avoid displaying it. For example, use generic text or blur images
  when explicit content or media are available.
- If the feature is very complex, consider separating the code into multiple files.
- Features that use buttons should follow extra requirements:
  - Promoting websites by them is prohibited.
  - They can't display information you couldn't fit in other fields.
  - Redirecting directly to audio/video stream is prohibited.
- Commits and PR titles **must** follow the [commit convention](COMMIT_CONVENTION.md).

## Modification

In some situations, features may behave unexpectedly or could use some minor changes to improve their functionality.
Here is a list of rules that you **must** follow while modifying features.

- If you make modifications to a feature and change at least a **quarter** of the feature's codebase, you are allowed
  to add yourself as a contributor. Contact a reviewer for more information about this subject.
- Anyone may create PRs to fix bugs. Do **not** change images if they are not outdated and are in specifications.

# Verification

> **All** code contributed will be licensed under the `GNU GPL 3`.

> If you need to contact someone, please use our official Discord server. All reviewers will have the `Tracker Dev` role
> on their profile.

> Please keep in mind that the reviewers work voluntarily and manage other repositories in addition to this one, your
> pull request may not get reviewed until hours or even days after it has been created.

> **Always** have an up-to-date fork before creating your pull request. This will help limit false positives from the
> checks.

The most important process of feature development is getting your changes merged. This is done by making
a [pull request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request)
on GitHub on the `TrackGeek/mobile` repository. Our reviewers will confirm that your changes are up to standards and
will merge them.

<div>
  <h2 style="font-size: 2rem; margin-bottom: 0;">Reviewers</h2>
  <a href="https://github.com/izakdvlpr"><img src="https://github.com/izakdvlpr.png?size=2048" title="izakdvlpr" width="48px" style="max-width:100%; border-radius: 50%;"/></a> <a href="https://github.com/Kuriel23"><img src="https://github.com/Kuriel23.png?size=2048" title="Kuriel23" width="48px" style="max-width:100%; border-radius: 50%;"/></a>
  <br />
</div>

## `Restrictions`

Repetitive offenses such as breaking guidelines, spamming pull requests, threats, or inappropriate behavior will get you
banned from contributing.

In this scenario, the following changes will occur:

- PRs under your management will be transferred to the TrackGeek bot or another user (reviewer decision).
- All of your issues and pull requests (feature creation, contribution, etc) created following the ban will be
  promptly closed.
- Tickets created under your name regarding development will be deleted.

## `Reviewing`

A few things you should know after opening a pull request:

- It takes 2 reviewers to merge a pull request.
- If a pull request is inactive for a period of 7 days, it will be promptly closed.
- All checks **must** be passed in order to merge.
- ⚠️ You **must** provide new, unaltered screenshots or recordings (taken by you) showing the new changes to prove that
  your PR works. _You are allowed to stitch screenshots together for viewing pleasure_ This applies for both creation
  and modification.

## `Checks`

Currently, a PR goes through the following checks. All of these help the reviewers determine whether your changes are
suitable for merging.

- `CodeRabbit` is a bot that checks for code quality. If you ever receive errors for new issues, you are **required** to
  fix them.
- `Check / format-analyze` runs `dart format --set-exit-if-changed lib test` and `flutter analyze`. If you ever receive
  errors for new issues, you are **required** to fix them.
- `Check / build` runs `flutter build apk --debug` to make sure the app still compiles.
- `Test / test` runs `flutter test -j 1`. All tests **must** pass.

# Suggestions

If you have some suggestions about our guidelines, you should contact
us @ [TrackGeek's Discord server](https://discord.trackgeek.net) and we will check them!

# Contributions

`Revision 1` was maintained by the following individuals:

<div>
<a href="https://github.com/Kuriel23"><img src="https://github.com/Kuriel23.png?size=2048" width="48px" style="max-width:100%; border-radius: 50%;"/></a>
</div>
