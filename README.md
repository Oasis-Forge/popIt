# popIt

A Flutter application (`pop_it`) targeting Android, iOS, web, Windows, macOS, and Linux.

The app currently contains the generated Flutter starter scaffold — a `MaterialApp` with a
Material 3 deep-purple color scheme and a counter home page — which serves as the base for
the features to come.

## Requirements

- Flutter SDK with Dart `^3.12.2`
- Platform toolchains for whichever targets you build (Android Studio / Xcode / Visual Studio)

Verify your setup with:

```bash
flutter doctor
```

## Getting started

Install dependencies:

```bash
flutter pub get
```

Run the app on a connected device or emulator:

```bash
flutter run
```

Pick a specific target with `-d`, for example:

```bash
flutter run -d chrome
```

## Project layout

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App entry point and root widget |
| `test/` | Widget and unit tests |
| `pubspec.yaml` | Package metadata and dependencies |
| `analysis_options.yaml` | Lint rules (`flutter_lints`) |
| `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` | Per-platform host projects |

## Development

Run the tests:

```bash
flutter test
```

Analyze and format:

```bash
flutter analyze
```

```bash
dart format .
```

## Building

```bash
flutter build apk
```

```bash
flutter build ios
```

```bash
flutter build web
```

## Resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
</content>
</invoke>
