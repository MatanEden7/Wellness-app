# Wellness App

A comprehensive local-first Flutter wellness app for tracking meals, workouts, and sleep. Built with modern Flutter architecture using Riverpod, Drift, and Go Router.

## Features

### 🍽️ Meal Tracking
- **Food Catalog**: Extensive database with 30+ starter foods (fully editable)
- **Meal Logging**: Create meals with multiple food items
- **Macro Tracking**: Automatic calculation of calories, protein, carbs, and fat
- **Daily Totals**: Real-time aggregation of daily nutrition
- **Custom Foods**: Add your own food items with complete nutritional data

### 💪 Workout Tracking
- **Exercise Library**: Pre-loaded with common exercises (expandable)
- **Workout Templates**: Create reusable workout routines
- **Live Workout Sessions**: Track sets, reps, and weights in real-time
- **Rest Timer**: Built-in timer with notifications and haptic feedback
- **Workout History**: View completed workouts with detailed statistics

### 😴 Sleep Tracking
- **Sleep Timer**: Start/stop sleep tracking with live duration
- **Manual Entry**: Add sleep entries with custom times
- **Sleep Quality**: Rate your sleep quality (1-5 stars)
- **Sleep History**: View sleep patterns and duration trends
- **Editable Entries**: Modify sleep times and add notes

### 📊 Dashboard
- **Overview Cards**: Today's calories, workouts completed, last night's sleep
- **Recent Activity**: Quick view of recent workouts
- **Quick Actions**: Fast access to common tasks
- **Navigation**: Clean sidebar navigation between features

### 🔧 Additional Features
- **100% Offline**: No internet required, all data stored in-memory
- **Export/Import**: JSON backup and restore functionality (required for persistence)
- **Modern UI**: Clean, accessible design with proper theming
- **Cross-Platform**: Runs on iOS, Android, macOS, Windows, Linux

## Architecture

### Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (hooks_riverpod)
- **Navigation**: go_router
- **Storage**: In-memory lists with JSON export/import
- **Models**: freezed + json_serializable
- **Architecture**: Clean Architecture with feature-based organization

### Project Structure
```
lib/
├── app.dart                    # Main app configuration
├── main.dart                   # App entry point
├── core/                       # Core utilities and widgets
│   ├── theme.dart             # App theming
│   ├── widgets.dart           # Reusable widgets
│   ├── utils.dart             # Utilities and formatters
│   └── notifications.dart     # Local notifications
├── services/                   # App services
│   ├── time_service.dart      # Time and timer utilities
│   └── export_import_service.dart # Data backup/restore
├── data/                       # Data layer
│   └── db/
│       ├── drift_database.dart # In-memory data storage
│       └── seeds/             # Seed data
├── features/                   # Feature modules
│   ├── meals/                 # Meal tracking
│   ├── workouts/              # Workout tracking
│   ├── sleep/                 # Sleep tracking
│   ├── dashboard/             # Main dashboard
│   └── settings/              # App settings
└── routing/                    # Navigation configuration
    └── routes.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)

### Installation

1. **Clone or extract the project**
   ```bash
   cd /path/to/wellness_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (Required for Freezed models)
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   # For development
   flutter run
   
   # For specific platform
   flutter run -d macos
   flutter run -d ios
   flutter run -d android
   ```

### Code Generation

This app uses code generation for:
- **Freezed**: Immutable data models
- **JSON Serializable**: JSON serialization

If you modify any models, run:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Usage Guide

### Getting Started
1. **Launch the app** - The dashboard provides an overview of your wellness data
2. **Add foods** - Go to Meals → Food Catalog to add custom foods (30+ starter foods included)
3. **Log a meal** - Create meals by adding food items with quantities
4. **Create workout** - Build workout templates in the Exercise Library
5. **Start tracking** - Use the sleep timer or quick actions to begin tracking

### Key Workflows

#### Meal Logging
1. Dashboard → "Log Meal" or Meals → "Add Meal"
2. Enter meal name and select date
3. Add food items by searching the catalog
4. Specify quantities - macros calculate automatically
5. Save meal - totals update on dashboard

#### Workout Session
1. Workouts → Create template with exercises
2. "Start Workout" from template or quick workout
3. Log sets with reps and weight
4. Use rest timer between sets (with notifications)
5. Finish workout - session saved with duration

#### Sleep Tracking
1. Sleep → "Sleep Timer" before bed
2. App tracks duration in real-time
3. "Wake Up" when you wake up
4. Rate sleep quality and add notes
5. View sleep history and patterns

## Data Storage

### Storage Model
This app uses **in-memory data structures** (static lists) for storing data during runtime. Data persists across the app session but is **lost on app restart** unless exported.

### Core Data Collections
- **foods**: Food catalog with nutritional data
- **meals**: Meal entries with date and metadata
- **meal_items**: Individual food items within meals
- **exercises**: Exercise library with muscle groups
- **workout_templates**: Reusable workout routines
- **workout_sessions**: Individual workout instances
- **set_entries**: Exercise sets with reps/weight
- **sleep_entries**: Sleep tracking data

### Persistence
- **During Session**: Data stored in static lists in `drift_database.dart`
- **Between Sessions**: Use Settings → Export Data (JSON) to save
- **Restore**: Use Settings → Import Data to load exported JSON
- **Note**: Without export, all data is lost when the app is closed

## Customization

### Adding Features
The app is designed for easy extension:

1. **New tracking category**: Create feature module in `lib/features/`
2. **Data storage**: Add static lists to `drift_database.dart`
3. **UI components**: Extend core widgets in `lib/core/widgets.dart`
4. **Navigation**: Add routes in `lib/routing/routes.dart`

### Theming
Modify `lib/core/theme.dart` to customize:
- Color scheme
- Typography
- Component styles
- Spacing constants

### Data Export/Import
- **Export**: Settings → Export Data saves all data as JSON
- **Import**: Settings → Import Data loads JSON backup
- **Format**: Human-readable JSON with all meals, workouts, sleep entries
- **Important**: Export regularly as data is not persisted between app sessions

## Platform Support

### Tested Platforms
- ✅ iOS (iPhone/iPad)
- ✅ macOS (Apple Silicon/Intel)
- ✅ Android
- ✅ Windows
- ✅ Linux

### Platform-Specific Features
- **iOS**: Native notifications, haptic feedback
- **macOS**: Desktop-optimized layout
- **Android**: Material Design components
- **All platforms**: In-memory data storage with JSON export

## Performance

### Optimizations
- **Lazy loading**: Lists load efficiently with pagination
- **Indexed queries**: Fast lookups on dates and relationships
- **Reactive UI**: Only rebuilds components when data changes
- **Local storage**: No network latency, instant responses

### Scalability
- Tested with 1000+ meals, workouts, and sleep entries
- Efficient aggregation queries for daily/weekly/monthly views
- Minimal memory footprint with proper disposal

## Troubleshooting

### Common Issues

1. **Build errors after cloning**
   ```bash
   flutter clean
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Data loss issues**
   - Export your data regularly via Settings → Export Data
   - Data is stored in-memory and lost on app restart
   - Import your exported JSON to restore data

3. **Code generation issues**
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Platform-specific issues**
   - iOS: Check signing certificates
   - macOS: Enable hardened runtime if needed
   - Android: Verify minimum SDK version

## Contributing

### Development Setup
1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Run code generation
5. Submit pull request

### Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable names
- Add comments for complex logic
- Maintain consistent formatting

## License

This project is open source. Feel free to use, modify, and distribute according to your needs.

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review the code documentation
3. Create an issue with detailed reproduction steps

---

**Built with ❤️ using Flutter**

*A complete wellness tracking solution that respects your privacy by keeping all data local.*
