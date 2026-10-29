<p align="center">
  <img src="https://github.com/TrackGeek.png" height="100px">
</p>

<h1 align="center">
  <samp>Mobile App</samp>
</h1>

<h4 align="center">
  <samp>Mobile app for Android and iOS to track all your media in one unified platform.</samp>
</h4>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-99e3a0?style=for-the-badge&logo=flutter&logoColor=FFFFFF">
  <img src="https://img.shields.io/badge/Dart-99e3a0?style=for-the-badge&logo=dart&logoColor=FFFFFF">
  <img src="https://img.shields.io/badge/Android-99e3a0?style=for-the-badge&logo=android&logoColor=FFFFFF">
  <img src="https://img.shields.io/badge/iOS-99e3a0?style=for-the-badge&logo=apple&logoColor=FFFFFF">
  <a href="https://translate.trackgeek.net"><img src="https://img.shields.io/badge/Crowdin-99e3a0?style=for-the-badge&logo=crowdin&logoColor=FFFFFF"></a>
</p>

## <samp>Features</samp>

<samp>

- Cross-platform app for Android and iOS built with Flutter;
- Track games, anime, movies, TV shows, books, and manga with progress system;
- Custom lists management;
- User profiles with favorites;
- Full i18n support;
- Feed with real-time updates;
- Push notifications for upcoming releases;
- Image gallery and screenshots;
- Content relationship viewer;
- Smooth animations and transitions;
- Responsive layouts for tablets.

</samp>

## <samp>Tech Stack</samp>

<samp>

- Flutter
- Dart
- Material Design 3
- http
- Google Sign-In & Passkeys
- flutter_local_notifications & Workmanager
- Shared Preferences
- flutter_svg & Hugeicons
- intl

</samp>

## <samp>Run Locally</samp>

<samp>

### Prerequisites

- Flutter SDK 3.13.7 or newer
- For Android: Android Studio, Android SDK, and a physical device or emulator
- For iOS: Xcode and CocoaPods on macOS, and a physical device or simulator

### Steps

1. Clone the project

```bash
git clone https://github.com/TrackGeek/mobile.git
```

2. Install dependencies

```bash
flutter pub get
```

3. Run the app

- Connect a device or start an emulator/simulator
- Launch with the API URL configured:

```bash
flutter run --dart-define=TRACKGEEK_API_URL=https://api.trackgeek.net
```

- Optionally set `TRACKGEEK_GOOGLE_CLIENT_ID` to enable Google sign-in

### Build

To generate release builds:

```bash
# Android
flutter build apk --release
# or
flutter build appbundle --release

# iOS
flutter build ios --release
```

The APK will be generated in `build/app/outputs/flutter-apk/`

</samp>

## <samp>Contributing</samp>

<samp>

Contributions are always welcome!

See `CONTRIBUTING.md` for ways to get started.

Please adhere to this project's `code of conduct`.

</samp>
