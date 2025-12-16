# Bird Watching Mobile App - Setup Instructions

## Google Maps API Key Configuration

This app requires Google Maps API keys for both iOS and Android platforms.

### 1. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
4. Create credentials (API Key)
5. Restrict the API key (recommended):
   - For Android: Add your app's package name and SHA-1 certificate fingerprint
   - For iOS: Add your app's bundle identifier

### 2. Configure Android

Edit `android/app/src/main/AndroidManifest.xml`:

Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

### 3. Configure iOS

Edit `ios/Runner/AppDelegate.swift`:

Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
```

### 4. Backend API Configuration

The app connects to the Bird Watching Platform backend API. You'll need to configure the API base URL.

This will be set up in the next task (1.4 - Set up project structure) in the constants file.

## Platform-Specific Setup

### iOS

Minimum iOS version: 13.0

Required permissions are already configured in `ios/Runner/Info.plist`:
- Camera access
- Photo library access
- Location access (when in use and always)

### Android

Minimum SDK: 21 (Android 5.0)
Target SDK: 34 (Android 14)

Required permissions are already configured in `android/app/src/main/AndroidManifest.xml`:
- Camera
- Location (fine, coarse, background)
- Storage (read/write external storage, read media images)
- Internet and network state

## Running the App

```bash
# Get dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Run on connected device
flutter run
```

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test
```

## Building for Release

### iOS

```bash
flutter build ios --release
```

### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## Notes

- Make sure to never commit your actual API keys to version control
- Consider using environment variables or a secrets management solution for production
- The app requires an active internet connection for initial setup and syncing
- Offline mode is supported for creating observations without connectivity
