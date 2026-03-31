# Cryptography Visualizer

A beginner-friendly Flutter app to learn and practice classical cryptography.

This project lets users encrypt and decrypt text with popular classical ciphers, view transformation steps, save history, and manage profile/settings using Firebase.

## Table of Contents

- [Project Purpose](#project-purpose)
- [Main Features](#main-features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [How to Run (Beginner Steps)](#how-to-run-beginner-steps)
- [Firebase Setup](#firebase-setup)
- [Build Release APK/AAB](#build-release-apkaab)
- [Common Issues and Fixes](#common-issues-and-fixes)
- [Useful Commands](#useful-commands)

## Project Purpose

The app is designed for students and beginners who want to:

- Understand how classical ciphers work.
- See step-by-step transformations for encryption/decryption.
- Practice with different cipher algorithms in one place.
- Store and review their cipher operation history.

## Main Features

- Authentication
	- Sign up and login flow.
	- Firebase authentication integration.

- Cipher Modules
	- Caesar Cipher
	- Playfair Cipher
	- Hill Cipher

- History Management
	- Per-user cloud history using Firestore.
	- Add, view, edit, delete history items.

- Notifications
	- Instant local notifications for app actions.
	- Scheduled reminder button (10-second reminder).

- Profile and Settings
	- Profile details (name, phone, gender, photo URL).
	- Theme mode support.
	- Notification preference toggle.

- API Data Screen
	- Displays cipher-related information in a dedicated screen.

## Tech Stack

- Flutter (Dart)
- Provider (state management)
- Firebase Core/Auth/Firestore
- Shared Preferences
- HTTP
- flutter_local_notifications + firebase_messaging

## Project Structure

```text
lib/
	config/        # App constants and theme
	models/        # Data models
	providers/     # Provider state classes
	screens/       # UI screens (auth, home, ciphers, history, profile, settings)
	services/      # Business logic, Firebase, notifications, APIs
	widgets/       # Reusable UI widgets
```

Other important folders:

- `assets/` for images/icons
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` for platform projects
- `test/` for tests

## Prerequisites

Install these first:

1. Flutter SDK (stable channel)
2. Dart SDK (comes with Flutter)
3. Android Studio or VS Code
4. Android SDK and emulator (or real Android device)
5. Firebase project (for auth + database features)

To check tools are installed:

```bash
flutter --version
flutter doctor
```

## How to Run (Beginner Steps)

1. Clone or download this repository.
2. Open the project folder in VS Code or Android Studio.
3. Install dependencies:

```bash
flutter pub get
```

4. Run on device/emulator:

```bash
flutter run
```

5. If build cache causes problems, use:

```bash
flutter clean
flutter pub get
flutter run
```

## Firebase Setup

This app uses Firebase services. Make sure your Firebase files are configured.

### Android

1. Create a Firebase project.
2. Register Android app in Firebase.
3. Download `google-services.json`.
4. Put it in:

```text
android/app/google-services.json
```

### FlutterFire configuration

If needed, regenerate Firebase options:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This updates:

```text
lib/firebase_options.dart
```

## Build Release APK/AAB

### Quick release build

```bash
flutter build apk --release
flutter build appbundle --release
```

### Output locations

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### Signing setup (Android)

Use the template file:

```text
android/key.properties.example
```

Create your own `android/key.properties` and set real keystore values for production signing.

## Common Issues and Fixes

### 1) Firebase not initialized / login issues

- Check `google-services.json` is in correct path.
- Run `flutter clean` then `flutter pub get`.
- Verify package name in Firebase matches app package.

### 2) Notifications not appearing

- Check app notification permission in Android settings.
- Make sure notifications are enabled in app settings screen.
- Reinstall app after permission/config changes.

### 3) Build errors after dependency updates

Run:

```bash
flutter clean
flutter pub get
flutter analyze
```

### 4) Release build fails

- Verify keystore config for signed builds.
- Confirm Gradle files are not using invalid keys.

## Useful Commands

Analyze project:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Build debug APK:

```bash
flutter build apk --debug
```

Build release APK:

```bash
flutter build apk --release
```

---

If you are new to Flutter, start with:

1. Run the app.
2. Open Caesar cipher screen.
3. Encrypt text and view steps.
4. Save to history.
5. Explore profile and settings screens.

This flow helps you understand the app quickly.
