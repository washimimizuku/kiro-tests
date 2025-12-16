# Bird Watching Mobile App

A Flutter mobile application for bird watching enthusiasts with offline support, GPS tracking, and photo capture capabilities. Record your bird observations in the field, even without internet connectivity, and sync them automatically when you're back online.

## Features

- 📱 **Cross-platform**: Native iOS and Android apps from a single codebase
- 📷 **Camera Integration**: Take photos of birds directly in the app with automatic compression
- 📍 **GPS Tracking**: Automatically capture precise location coordinates for each observation
- 🔄 **Offline Mode**: Record observations without internet and sync automatically when connected
- 🗺️ **Interactive Maps**: Visualize your observations on a map with marker clustering
- 🔐 **Secure Authentication**: Encrypted credential storage using platform secure storage
- 📊 **Trip Management**: Organize observations into trips for better tracking
- 👥 **Community**: Browse and discover observations shared by other bird watchers
- 🔍 **Search & Filter**: Find observations by species, location, or date range
- 💾 **Smart Caching**: Efficient local data storage with automatic cache management
- ♿ **Accessibility**: Full support for screen readers, dynamic font sizing, and high contrast mode
- 🎨 **Modern UI**: Clean, intuitive interface optimized for field use

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── core/                     # Core utilities and constants
│   ├── constants/           # App-wide constants
│   ├── theme/              # Theme configuration
│   ├── utils/              # Utility functions
│   └── errors/             # Error handling
├── data/                    # Data layer
│   ├── models/             # Data models
│   ├── repositories/       # Repository implementations
│   ├── services/           # Services (API, database, etc.)
│   └── data_sources/       # Local and remote data sources
├── domain/                  # Domain layer
│   ├── entities/           # Business entities
│   └── use_cases/          # Business logic use cases
├── presentation/            # Presentation layer
│   ├── blocs/              # BLoC state management
│   ├── screens/            # UI screens
│   └── widgets/            # Reusable widgets
└── config/                  # App configuration
    ├── routes.dart         # Route definitions
    └── dependency_injection.dart  # DI setup
```

## Screenshots

_Screenshots will be added here showing:_
- Login screen
- Observation list with thumbnails
- Observation creation form with camera and GPS
- Map view with observation markers
- Trip management
- Community shared observations

## Getting Started

### Prerequisites

- **Flutter SDK**: 3.16 or higher ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart**: 3.2 or higher (included with Flutter)
- **iOS Development** (for iOS builds):
  - macOS with Xcode 15+
  - iOS Simulator or physical iOS device (iOS 13.0+)
  - CocoaPods (`sudo gem install cocoapods`)
- **Android Development** (for Android builds):
  - Android Studio with Android SDK
  - Android Emulator or physical Android device (API 21+)
- **Google Maps API Key**: Required for map functionality
- **Backend API**: Running instance of the Bird Watching Platform backend

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd my-birds/bird-watching-mobile
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install iOS dependencies** (macOS only)
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Configure Google Maps API keys**
   
   See [SETUP.md](SETUP.md) for detailed instructions on obtaining and configuring Google Maps API keys for both platforms.
   
   Quick setup:
   - **iOS**: Add your key to `ios/Runner/AppDelegate.swift`
   - **Android**: Add your key to `android/app/src/main/AndroidManifest.xml`

5. **Configure backend API URL**
   
   Edit `lib/core/constants/app_constants.dart` and update the `apiBaseUrl`:
   ```dart
   static const String apiBaseUrl = 'https://your-backend-api.com';
   ```

6. **Verify setup**
   ```bash
   flutter doctor
   ```
   Ensure all checks pass for your target platform.

7. **Run the app**
   ```bash
   # List available devices
   flutter devices
   
   # Run on iOS simulator
   flutter run -d "iPhone 14 Pro"
   
   # Run on Android emulator
   flutter run -d emulator-5554
   
   # Run on connected device
   flutter run
   ```

### First Run

On first launch, the app will:
1. Initialize the local database
2. Request necessary permissions (camera, location, storage)
3. Display the login screen

**Test Credentials** (if using development backend):
- Username: `testuser`
- Password: `testpass123`

## Architecture

This app follows Clean Architecture principles with separation of concerns:

- **Presentation Layer**: UI components and state management (BLoC pattern)
- **Domain Layer**: Business logic and entities
- **Data Layer**: Data sources, repositories, and models

### State Management

Using **flutter_bloc** for predictable state management with the BLoC pattern.

### Dependency Injection

Using **get_it** for service location and dependency injection.

## Key Dependencies

### Core Framework
- **flutter**: 3.16+ - Cross-platform UI framework
- **dart**: 3.2+ - Programming language

### State Management
- **flutter_bloc**: ^8.1.3 - BLoC pattern implementation
- **equatable**: ^2.0.5 - Value equality for states

### Networking & Storage
- **dio**: ^5.4.0 - HTTP client for API communication
- **sqflite**: ^2.3.0 - SQLite database for local storage
- **flutter_secure_storage**: ^9.0.0 - Secure credential storage
- **shared_preferences**: ^2.2.2 - Simple key-value storage
- **path_provider**: ^2.1.1 - File system paths

### Location & Maps
- **geolocator**: ^10.1.0 - GPS location services
- **google_maps_flutter**: ^2.5.0 - Google Maps integration
- **geocoding**: ^2.1.1 - Reverse geocoding (optional)

### Media & Images
- **image_picker**: ^1.0.5 - Camera and gallery access
- **flutter_image_compress**: ^2.1.0 - Image compression
- **cached_network_image**: ^3.3.0 - Image caching

### Utilities
- **connectivity_plus**: ^5.0.2 - Network connectivity monitoring
- **permission_handler**: ^11.1.0 - Permission management
- **intl**: ^0.18.1 - Internationalization and date formatting
- **uuid**: ^4.2.2 - UUID generation
- **rxdart**: ^0.27.7 - Reactive extensions

### Dependency Injection
- **get_it**: ^7.6.4 - Service locator

### Testing
- **flutter_test**: SDK - Widget and unit testing
- **mockito**: ^5.4.4 - Mocking for tests
- **build_runner**: ^2.4.7 - Code generation

See [pubspec.yaml](pubspec.yaml) for the complete list with exact versions.

## Development

### Running Tests

The app includes comprehensive test coverage:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/repositories/auth_repository_unit_test.dart

# Run tests with coverage
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Test Categories:**
- **Unit Tests**: Repository and service tests (`test/repositories/`, `test/services/`)
- **Widget Tests**: UI component tests (`test/screens/`, `test/widgets/`)
- **Integration Tests**: End-to-end flow tests (`test/integration/`)
- **Property-Based Tests**: Correctness property tests (`test/*_property_test.dart`)

### Code Generation

Some features require code generation (mocks, JSON serialization):

```bash
# Generate code
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on changes)
dart run build_runner watch --delete-conflicting-outputs
```

### Linting & Analysis

```bash
# Run static analysis
flutter analyze

# Format code
dart format lib/ test/

# Check formatting
dart format --set-exit-if-changed lib/ test/
```

### Debugging

**Enable Debug Logging:**
- Set `debugMode = true` in `app_constants.dart`
- View logs in console or device logs

**Common Debug Commands:**
```bash
# View device logs (iOS)
flutter logs

# View device logs (Android)
adb logcat

# Debug with DevTools
flutter run --observatory-port=8888
```

### Hot Reload & Hot Restart

- **Hot Reload**: Press `r` in terminal (preserves app state)
- **Hot Restart**: Press `R` in terminal (resets app state)
- **Quit**: Press `q` in terminal

## Building for Release

### iOS Release Build

1. **Configure signing** in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
   - Select Runner target
   - Go to "Signing & Capabilities"
   - Select your development team
   - Configure provisioning profiles

2. **Build for release**:
   ```bash
   flutter build ios --release
   ```

3. **Archive and submit**:
   - In Xcode: Product → Archive
   - Upload to App Store Connect
   - Submit for review

See [ios/IOS_CONFIGURATION.md](ios/IOS_CONFIGURATION.md) for detailed instructions.

### Android Release Build

1. **Configure signing** (first time only):
   ```bash
   # Generate keystore
   keytool -genkey -v -keystore ~/bird-watching-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias bird-watching
   
   # Create key.properties
   echo "storePassword=<password>" > android/key.properties
   echo "keyPassword=<password>" >> android/key.properties
   echo "keyAlias=bird-watching" >> android/key.properties
   echo "storeFile=<path-to-keystore>" >> android/key.properties
   ```

2. **Build APK** (for direct distribution):
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

3. **Build App Bundle** (recommended for Play Store):
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`

4. **Upload to Play Console**:
   - Go to Google Play Console
   - Create a new release
   - Upload the `.aab` file
   - Complete store listing and submit for review

See [android/ANDROID_CONFIGURATION.md](android/ANDROID_CONFIGURATION.md) for detailed instructions.

### Build Optimization

```bash
# Build with code shrinking (smaller app size)
flutter build apk --release --shrink

# Build with split APKs per ABI (smaller downloads)
flutter build apk --release --split-per-abi

# Analyze app size
flutter build apk --release --analyze-size
```

## Backend Integration

This app connects to the Bird Watching Platform backend API (Rust/Actix-web).

**Backend Repository**: `my-birds/bird-watching-backend`

**API Endpoints Used:**
- `POST /auth/login` - User authentication
- `POST /auth/register` - User registration
- `GET /observations` - Fetch observations
- `POST /observations` - Create observation
- `PUT /observations/:id` - Update observation
- `DELETE /observations/:id` - Delete observation
- `GET /trips` - Fetch trips
- `POST /trips` - Create trip
- `POST /photos/upload` - Upload photo

**Configuration:**
- Update `apiBaseUrl` in `lib/core/constants/app_constants.dart`
- Ensure backend is running and accessible from your device/emulator
- For local development, use appropriate localhost addresses:
  - iOS Simulator: `http://localhost:8080`
  - Android Emulator: `http://10.0.2.2:8080`
  - Physical Device: Use your computer's IP address

## Performance Optimization

The app includes several performance optimizations:

- **Image Optimization**: Automatic compression and lazy loading
- **Database Indexing**: Optimized queries for fast data retrieval
- **Smart Caching**: LRU cache with automatic eviction
- **Pagination**: Load data in chunks to reduce memory usage
- **Code Splitting**: Lazy loading of features

See [PERFORMANCE_OPTIMIZATION.md](PERFORMANCE_OPTIMIZATION.md) for details.

## Accessibility

The app is fully accessible with support for:

- Screen readers (TalkBack, VoiceOver)
- Dynamic font sizing
- High contrast mode
- Keyboard navigation
- Semantic labels for all interactive elements

See [ACCESSIBILITY.md](ACCESSIBILITY.md) for details.

## Troubleshooting

### Common Issues

**Build Errors:**
```bash
# Clean build cache
flutter clean
flutter pub get

# Regenerate platform files
flutter create .

# iOS: Clean pods
cd ios && pod deintegrate && pod install && cd ..
```

**Permission Issues:**
- Ensure permissions are properly configured in Info.plist (iOS) and AndroidManifest.xml (Android)
- Check that permission descriptions are user-friendly
- Test permission flows on real devices

**Map Not Showing:**
- Verify Google Maps API key is configured correctly
- Ensure API key has Maps SDK enabled in Google Cloud Console
- Check that billing is enabled for the Google Cloud project

**Offline Sync Issues:**
- Check connectivity service is working
- Verify local database is initialized
- Check sync service logs for errors

### Getting Help

1. Check existing documentation in the `docs/` folder
2. Review platform-specific configuration guides
3. Check the issue tracker for known issues
4. Contact the development team

## Contributing

We welcome contributions! Please follow these guidelines:

1. **Code Style**: Follow the existing code structure and patterns
2. **Testing**: Write tests for new features (unit, widget, and integration tests)
3. **Documentation**: Update documentation for any changes
4. **Linting**: Run `flutter analyze` before committing
5. **Commits**: Use clear, descriptive commit messages
6. **Pull Requests**: Provide detailed description of changes

### Development Workflow

1. Create a feature branch from `main`
2. Make your changes with tests
3. Run tests and linter
4. Submit a pull request
5. Address review feedback

## Project Status

**Current Version**: 1.0.0

**Completed Features:**
- ✅ Authentication (login, registration, logout)
- ✅ Observation CRUD operations
- ✅ Offline mode with automatic sync
- ✅ Camera integration with photo compression
- ✅ GPS location tracking
- ✅ Map visualization with clustering
- ✅ Trip management
- ✅ Community shared observations
- ✅ Search and filtering
- ✅ Accessibility support
- ✅ Performance optimizations

**Upcoming Features:**
- 🔄 Biometric authentication
- 🔄 Dark mode
- 🔄 Multiple language support
- 🔄 Bird species autocomplete
- 🔄 Export observations to CSV/GPX

## License

Private project - All rights reserved

## Support

For issues, questions, or feature requests:
- **Email**: support@birdwatching.com
- **Issue Tracker**: [GitHub Issues](link-to-issues)
- **Documentation**: See the `docs/` folder for detailed guides

## Acknowledgments

Built with Flutter and the amazing Flutter community packages. Special thanks to all contributors and the bird watching community for their feedback and support.
