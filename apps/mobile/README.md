# AniCine Home - Mobile App

A Flutter-based mobile streaming service app for watching anime content, built on top of the AniCine API.

## Features

### 🏠 Home Screen
- **Spotlight Section**: Featured anime carousel with images and descriptions
- **Trending Now**: Horizontal scrollable list of currently trending anime
- **Latest Episodes**: Recently released episodes
- **Top Upcoming**: Upcoming anime releases
- **Top Airing**: Currently airing popular shows
- **Pull to Refresh**: Refresh content with a swipe down
- **Quick Search**: Access search functionality from the app bar
- **Categories Menu**: Browse by genre, type, or popularity

### 🔍 Search Screen
- Real-time anime search
- Grid layout with poster images
- Search suggestions as you type
- Tap any result to view details

### 📺 Anime Details Screen
- **Collapsible Header**: Large poster image with scrollable content
- **Complete Information**: Type, status, episode count, genres
- **Synopsis**: Full description of the anime
- **Episode List**: Browse all available episodes
- **Tap to Play**: Select any episode to watch (player functionality ready for integration)

### 📂 Category Screen
- Browse anime by specific categories:
  - Genres (Action, Comedy, Drama, Romance, etc.)
  - Types (TV, Movie, OVA, Special, etc.)
  - Lists (Top Airing, Most Popular, Recently Updated, etc.)
- Grid layout for easy browsing
- Pull to refresh

## Project Structure

```
lib/
├── main.dart                   # App entry point
├── models/
│   └── anime.dart             # Data models (Anime, Episode)
├── services/
│   └── api.dart               # API service with all endpoints
└── screens/
    ├── home_screen.dart       # Main home screen with categories
    ├── anime_details_screen.dart  # Detailed anime information
    ├── search_screen.dart     # Search functionality
    └── category_screen.dart   # Category browsing
```

## API Endpoints Used

The app leverages the following API endpoints:

- `GET /` - Home page data (spotlight, trending, latest episodes)
- `GET /top-ten` - Top 10 anime
- `GET /info?id={animeId}` - Detailed anime information
- `GET /random` - Random anime
- `GET /{category}` - Category-specific anime lists
- `GET /search?keyword={query}` - Search anime

### Available Categories
- **Popularity**: top-airing, most-popular, most-favorite, recently-updated
- **Genres**: action, adventure, comedy, drama, romance, horror, etc.
- **Types**: movie, tv, special, ova, ona
- **A-Z Lists**: Browse alphabetically

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- An Android or iOS device/emulator

### Installation

1. **Install Dependencies**
   ```bash
   cd app
   flutter pub get
   ```

2. **Configure API Endpoint**
   Update the `baseUrl` in `lib/services/api.dart`:
   ```dart
   final String baseUrl = "http://YOUR_API_HOST:4444/api";
   ```
   
   > **Note**: Make sure your API server is running and accessible from your device/emulator.

3. **Run the App**
   ```bash
   flutter run
   ```

### For Android Emulator
If using Android emulator and the API is on `localhost`, use:
```dart
final String baseUrl = "http://10.0.2.2:4444/api";
```

### For iOS Simulator
If using iOS simulator and the API is on `localhost`, use:
```dart
final String baseUrl = "http://localhost:4444/api";
```

### For Physical Device
Use your computer's local network IP address:
```dart
final String baseUrl = "http://192.168.X.X:4444/api";
```

## Theming

The app uses Material Design 3 with a dark theme:
- **Primary Color**: Deep Purple
- **Dark Mode**: Default theme
- **Material 3**: Modern UI components

To customize the theme, edit `main.dart`:
```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, // Change this
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
),
```

## Next Steps / TODO

### Video Player Integration
To add actual video playback functionality:

1. Add video player package to `pubspec.yaml`:
   ```yaml
   dependencies:
     video_player: ^2.8.0
     # or
     chewie: ^1.7.0
   ```

2. Create a new screen `video_player_screen.dart`

3. Fetch streaming URLs from the API episode endpoint

4. Implement the video player with controls

### Additional Features
- [ ] User authentication
- [ ] Favorites/Watchlist
- [ ] Watch history
- [ ] Continue watching
- [ ] Offline downloads
- [ ] Comments and ratings
- [ ] Recommendations
- [ ] Multiple audio/subtitle tracks
- [ ] Picture-in-picture mode
- [ ] Chromecast support

## Dependencies

- `flutter`: SDK
- `http`: ^1.5.0 - For API requests
- `cupertino_icons`: ^1.0.8 - iOS-style icons

## Troubleshooting

### "Failed to load data" Error
- Verify the API server is running
- Check the `baseUrl` configuration
- Ensure network connectivity
- Check firewall settings

### Images Not Loading
- Verify image URLs from the API
- Check internet permissions (Android: AndroidManifest.xml)
- Try a different network connection

### Android Network Error
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## License

This project follows the same license as the API server.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

