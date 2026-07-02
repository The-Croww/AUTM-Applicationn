# Firebase Setup Guide for AuTOMATO

This guide explains how to configure Firebase to connect your Flutter app with the ESP32 firmware.

## Prerequisites

1. A Firebase project created at [console.firebase.google.com](https://console.firebase.google.com)
2. Flutter project with Firebase dependencies already added (already in `pubspec.yaml`)

## Step 1: Install Firebase CLI

```bash
# On Windows (using PowerShell)
winget install Google.FirebaseCLI

# Or download from https://firebase.google.com/docs/cli
```

## Step 2: Login to Firebase

```bash
firebase login
```

## Step 3: Configure FlutterFire

Run the following command in your project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This will:
- Link your Flutter project to your Firebase project
- Download `google-services.json` for Android
- Download `GoogleService-Info.plist` for iOS

Select your Firebase project when prompted, and select the platforms you want to support (Android/iOS).

## Step 4: Android Configuration

The `flutterfire configure` command should have already placed `google-services.json` in `android/app/`.

If not, manually download it:
1. Go to Firebase Console → Project Settings
2. Select your Android app
3. Download `google-services.json`
4. Place it in `android/app/`

### Update android/build.gradle

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

### Update android/app/build.gradle

Add this at the TOP of the file:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## Step 5: iOS Configuration

The `flutterfire configure` command should have already placed `GoogleService-Info.plist` in `ios/Runner/`.

If not, manually download it:
1. Go to Firebase Console → Project Settings
2. Select your iOS app
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

### Update ios/Runner/Info.plist

Add the following keys to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture plant photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save plant photos</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs photo library access to save plant photos</string>
```

### Update ios/Podfile

Ensure your Podfile includes Firebase pods (usually handled automatically by Flutter):

```ruby
platform :ios, '12.0'
```

Then run:

```bash
cd ios
pod install
cd ..
```

## Step 6: Firebase Realtime Database Rules

Set up your Realtime Database rules in Firebase Console → Realtime Database → Rules:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    "sensors": {
      ".indexOn": ["timestamp"]
    },
    "history": {
      "$sensorId": {
        ".indexOn": ["timestamp"]
      }
    },
    "alerts": {
      ".indexOn": ["createdAt"]
    },
    "devices": {
      ".indexOn": ["lastTriggered"]
    }
  }
}
```

These rules require authentication for all read/write operations and add indexes for common queries.

## Step 7: Enable Authentication

In Firebase Console:
1. Go to Authentication → Sign-in method
2. Enable Email/Password
3. Enable Google Sign-In

## Step 8: Test the Connection

Run your app:

```bash
flutter run
```

The app should now:
- Connect to Firebase on startup
- Show the login screen
- After login, attempt to read from Firebase Realtime Database
- Display sensor data from your ESP32

## Troubleshooting

### "FirebaseApp not initialized"
- Ensure `Firebase.initializeApp()` is called in `main()` before any Firebase operations
- Check that `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location

### "Permission denied" errors
- Check Firebase Realtime Database rules
- Ensure user is authenticated before accessing data
- Verify the database structure matches the RTDB contract in README.md

### No data appearing
- Ensure ESP32 is running and writing to Firebase
- Check Firebase Console → Realtime Database to verify data is being written
- Verify the database paths match what the app expects (see RTDB contract in README.md)

### Google Sign-In fails
- Ensure SHA-1 fingerprint is added to Firebase Console for Android
- For iOS, ensure the bundle ID matches what's configured in Firebase Console

## RTDB Contract Reference

The ESP32 firmware writes to the following paths (from README.md):

| Path | Direction | Notes |
|------|-----------|-------|
| `/config/sensors/{id}` | write (boot) | label/unit/min/max/warning thresholds/icon |
| `/config/automationRules/*` | write (boot) | informational, mirrors app display |
| `/sensors/{id}` | write | { value, timestamp(ms), connected } |
| `/history/{id}/{ms}` | write | throttled to once/min |
| `/system/lastSeen` | write | **milliseconds**, heartbeat each cycle |
| `/system/firmwareVersion` | write | |
| `/alerts/{pushKey}` | write | created on threshold breach, resolved on recovery |
| `/commands/{deviceId}` | read + ack | applies command, sets status=acknowledged |
| `/devices/{deviceId}` | write | real actuator state after applying command/automation |

All timestamps are **milliseconds since epoch**.

## Switching Back to Mock Data

If you need to test without Firebase, you can switch back to mock repositories in `lib/main.dart`:

```dart
// ── Wire repositories ─────────────────────────────────────────
// Using mock repositories for development
final sensorRepo = MockSensorRepository();
final deviceRepo = MockDeviceRepository();
final alertRepo  = MockAlertRepository(sensorRepo.sensorStream);
final systemRepo = MockSystemRepository();
final cameraRepo = MockCameraRepository();
```
