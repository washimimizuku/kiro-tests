# iOS Configuration Summary

## Permissions Configured

The following permissions are configured in `Info.plist`:

### Camera Permission
- **NSCameraUsageDescription**: "This app needs access to your camera to take photos of birds you observe."

### Photo Library Permissions
- **NSPhotoLibraryUsageDescription**: "This app needs access to your photo library to select bird photos."
- **NSPhotoLibraryAddUsageDescription**: "This app needs access to save bird photos to your photo library."

### Location Permissions
- **NSLocationWhenInUseUsageDescription**: "This app needs your location to record where you observed birds."
- **NSLocationAlwaysAndWhenInUseUsageDescription**: "This app needs your location to record where you observed birds, even when the app is in the background."
- **NSLocationAlwaysUsageDescription**: "This app needs your location to record where you observed birds."

## App Icons

App icons are configured in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` with all required sizes:
- 1024x1024 (App Store)
- 20x20, 29x29, 40x40, 60x60, 76x76, 83.5x83.5 (various device sizes and contexts)
- All @1x, @2x, and @3x variants

## Launch Screen

Launch images are configured in `ios/Runner/Assets.xcassets/LaunchImage.imageset/` with:
- LaunchImage.png (@1x)
- LaunchImage@2x.png (@2x)
- LaunchImage@3x.png (@3x)

## Minimum iOS Version

- **Minimum Deployment Target**: iOS 13.0
- Configured in `ios/Podfile` and Xcode project settings

## Bundle Identifier

- **Bundle ID**: Configured via `$(PRODUCT_BUNDLE_IDENTIFIER)` in Info.plist
- Set in Xcode project settings

## Supported Orientations

### iPhone
- Portrait
- Landscape Left
- Landscape Right

### iPad
- Portrait
- Portrait Upside Down
- Landscape Left
- Landscape Right

## Testing Checklist

### Simulator Testing
- [ ] Test on iPhone SE (small screen)
- [ ] Test on iPhone 14 Pro (standard screen)
- [ ] Test on iPhone 14 Pro Max (large screen)
- [ ] Test on iPad (tablet)

### Device Testing
- [ ] Test camera functionality on real device
- [ ] Test GPS location on real device
- [ ] Test photo library access
- [ ] Test offline mode
- [ ] Test background location (if needed)

### Permission Testing
- [ ] Verify camera permission prompt appears
- [ ] Verify location permission prompt appears
- [ ] Verify photo library permission prompt appears
- [ ] Test app behavior when permissions are denied
- [ ] Test app behavior when permissions are granted

## Signing and Provisioning

### Development
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Go to "Signing & Capabilities"
4. Select your development team
5. Xcode will automatically manage provisioning profiles

### Distribution (App Store)
1. Create an App Store Connect record
2. Generate distribution certificates and provisioning profiles
3. Configure in Xcode under "Signing & Capabilities"
4. Use "Archive" to create a build for submission

## Build Commands

### Debug Build
```bash
flutter build ios --debug
```

### Release Build
```bash
flutter build ios --release
```

### Run on Simulator
```bash
flutter run -d "iPhone 14 Pro"
```

### Run on Device
```bash
flutter run -d <device-id>
```

## Notes

- All required permissions are properly configured with user-friendly descriptions
- App icons and launch screens are in place
- The app is configured for iOS 13.0 and above
- Signing and provisioning must be configured in Xcode before deploying to devices or App Store
