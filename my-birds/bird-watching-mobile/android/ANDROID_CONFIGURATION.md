# Android Configuration Summary

## Permissions Configured

The following permissions are configured in `AndroidManifest.xml`:

### Camera Permission
- **android.permission.CAMERA**: Required for taking bird photos
- **android.hardware.camera**: Marked as not required (allows installation on devices without camera)

### Location Permissions
- **android.permission.ACCESS_FINE_LOCATION**: For precise GPS coordinates
- **android.permission.ACCESS_COARSE_LOCATION**: For approximate location
- **android.permission.ACCESS_BACKGROUND_LOCATION**: For background location tracking (if needed)

### Storage Permissions
- **android.permission.READ_EXTERNAL_STORAGE**: For reading photos from storage
- **android.permission.WRITE_EXTERNAL_STORAGE**: For saving photos (maxSdkVersion="32" for Android 12 and below)
- **android.permission.READ_MEDIA_IMAGES**: For Android 13+ photo access

### Network Permissions
- **android.permission.INTERNET**: For API communication
- **android.permission.ACCESS_NETWORK_STATE**: For checking connectivity status

## App Icons

App icons are configured in `android/app/src/main/res/` with all required densities:
- **mipmap-mdpi**: 48x48 px
- **mipmap-hdpi**: 72x72 px
- **mipmap-xhdpi**: 96x96 px
- **mipmap-xxhdpi**: 144x144 px
- **mipmap-xxxhdpi**: 192x192 px

## Splash Screen

Launch background is configured in:
- `drawable/launch_background.xml` (Android < 21)
- `drawable-v21/launch_background.xml` (Android 21+)

## SDK Versions

Configured in `android/app/build.gradle.kts`:
- **minSdk**: 21 (Android 5.0 Lollipop)
- **targetSdk**: Latest Flutter target SDK
- **compileSdk**: Latest Flutter compile SDK

## Application ID

- **Package Name**: `com.birdwatching.bird_watching_mobile`
- Configured in `build.gradle.kts`

## Google Maps Configuration

Google Maps API key placeholder is configured in AndroidManifest.xml:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
```

**Note**: Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual Google Maps API key before deployment.

## Build Configuration

### Java/Kotlin Version
- **Java Version**: 17
- **Kotlin JVM Target**: 17

### Build Types
- **Debug**: Uses debug signing config
- **Release**: Currently uses debug signing (needs production signing config)

## Testing Checklist

### Emulator Testing
- [ ] Test on Android 5.0 (API 21) - minimum supported version
- [ ] Test on Android 10 (API 29) - common version
- [ ] Test on Android 13 (API 33) - latest version
- [ ] Test on different screen sizes (phone, tablet)

### Device Testing
- [ ] Test camera functionality on real device
- [ ] Test GPS location on real device
- [ ] Test photo storage access
- [ ] Test offline mode
- [ ] Test background location (if needed)

### Permission Testing
- [ ] Verify camera permission prompt appears
- [ ] Verify location permission prompt appears
- [ ] Verify storage permission prompt appears
- [ ] Test app behavior when permissions are denied
- [ ] Test app behavior when permissions are granted
- [ ] Test runtime permission requests (Android 6.0+)

## Signing Configuration

### Debug Signing
- Uses default Flutter debug keystore
- Located at: `~/.android/debug.keystore`

### Release Signing
1. Generate a keystore:
```bash
keytool -genkey -v -keystore ~/bird-watching-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias bird-watching
```

2. Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=bird-watching
storeFile=<path-to-keystore>
```

3. Update `android/app/build.gradle.kts` to use release signing config

### Play Store Signing
- Consider using Google Play App Signing for additional security
- Upload your signing key to Google Play Console

## Build Commands

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
```

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### Run on Emulator
```bash
flutter run -d emulator-5554
```

### Run on Device
```bash
flutter run -d <device-id>
```

### List Devices
```bash
flutter devices
```

## Play Store Preparation

### Before Submission
1. Configure release signing
2. Replace Google Maps API key with production key
3. Test thoroughly on multiple devices
4. Prepare store listing assets:
   - App icon (512x512 px)
   - Feature graphic (1024x500 px)
   - Screenshots (various sizes)
   - App description and metadata

### Content Rating
- Complete the content rating questionnaire in Play Console
- Bird watching app should receive appropriate rating

### Privacy Policy
- Required for apps that access sensitive permissions
- Must be hosted on a publicly accessible URL

## Notes

- All required permissions are properly configured
- App icons and splash screens are in place
- Minimum SDK is set to 21 (Android 5.0)
- Google Maps API key needs to be configured before deployment
- Release signing configuration must be set up before Play Store submission
- Consider implementing ProGuard/R8 rules for code obfuscation in release builds
