# Wellness App - Complete Technical Specification

## 📱 App Overview
**Name**: Wellness Tracker  
**Platform**: Flutter (iOS/Android)  
**Language**: Dart  
**Target**: iPhone 15, Hebrew/English RTL support  
**Architecture**: Clean Architecture with Riverpod state management  

---

## 🛠️ Technology Stack

### **Core Framework**
- **Flutter SDK**: Latest stable
- **Dart**: Latest stable
- **Target Platforms**: iOS (iPhone 15), Android

### **State Management**
- **Riverpod**: `hooks_riverpod: ^2.4.9`
- **Flutter Hooks**: `flutter_hooks: ^0.20.3`
- **Pattern**: Provider-based reactive state management

### **Database & Storage**
- **Local Database**: Drift (SQLite wrapper)
- **Preferences**: SharedPreferences
- **Storage Location**: 
  - iOS: `~/Library/Application Support/`
  - Android: `/data/data/com.example.wellness_app/`

### **Navigation**
- **Router**: GoRouter `go_router: ^12.1.3`
- **Pattern**: Declarative routing with type-safe navigation

### **UI Components**
- **Calendar**: `table_calendar: ^3.0.9`
- **Localization**: `flutter_localizations`, `intl: ^0.19.0`
- **Theme**: Custom Material Design 3 themes (Light/Dark/Gold)

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp configuration
├── core/                              # Shared utilities
│   ├── theme.dart                     # Theme definitions (Light/Dark/Gold)
│   ├── widgets.dart                   # Reusable UI components
│   └── utils.dart                     # Utility functions & formatters
├── data/
│   └── db/
│       ├── drift_database.dart        # Database schema & DAOs
│       └── drift_database.g.dart      # Generated database code
├── features/                          # Feature modules
│   ├── dashboard/
│   │   └── ui/dashboard_page.dart     # Main dashboard with 3-card layout
│   ├── meals/
│   │   ├── domain/models.dart         # Meal, FoodItem, DayTotals models
│   │   ├── data/repositories.dart     # MealsRepository
│   │   └── ui/                        # Meals pages & meal editor
│   ├── workouts/
│   │   ├── domain/models.dart         # Workout, Template, Exercise models
│   │   ├── data/                      # Repositories & providers
│   │   └── ui/                        # Workout pages & session tracking
│   ├── sleep/
│   │   ├── domain/models.dart         # SleepEntry model
│   │   ├── data/repositories.dart     # SleepRepository
│   │   └── ui/sleep_page.dart         # Sleep tracking interface
│   ├── calendar/
│   │   ├── domain/models.dart         # CalendarState, ScheduledEvent
│   │   ├── data/calendar_service.dart # Calendar data management
│   │   └── ui/calendar_page.dart      # Calendar with drag-sheet agenda
│   └── settings/
│       └── ui/settings_stub.dart      # Settings with nutrition goals
├── services/                          # Global services
│   ├── preferences_service.dart       # User preferences & nutrition goals
│   ├── theme_service.dart            # Theme switching service
│   ├── language_service.dart         # Localization & RTL support
│   ├── background_refresh_service.dart # Auto-refresh system
│   └── time_service.dart             # Date/time utilities
├── routing/
│   └── routes.dart                   # Route definitions & navigation
└── l10n/                             # Localization files
    ├── app_en.arb                    # English translations
    └── app_he.arb                    # Hebrew translations (RTL)
```

---

## 🗃️ Database Schema (Drift/SQLite)

### **Tables**
```sql
-- Food catalog
foods (id, name, kcal_per_unit, protein_per_unit, carbs_per_unit, fat_per_unit)

-- User meals
meals (id, name, logged_at)
meal_items (id, meal_id, food_id, quantity)

-- Workout templates
workout_templates (id, name, notes, created_at)
template_exercises (id, template_id, name, sets, reps, weight, rest_seconds)

-- Workout sessions
workout_sessions (id, template_id, started_at, ended_at, notes)
set_entries (id, session_id, exercise_name, set_number, reps, weight)

-- Sleep tracking
sleep_entries (id, bedtime, wake_time, quality, notes)
```

### **Data Access Objects (DAOs)**
- `FoodsDao`: Food catalog management
- `MealsDao`: Meal logging & daily totals calculation
- `WorkoutTemplatesDao`: Template CRUD operations
- `WorkoutSessionsDao`: Session tracking & history
- `SleepDao`: Sleep entry management

---

## 🎨 UI Architecture

### **Design System**
- **Material Design 3**: Latest design tokens
- **Responsive**: Mobile-first, desktop-adaptive layouts
- **Safe Area**: iPhone 15 Dynamic Island compatibility
- **RTL Support**: Hebrew right-to-left text direction

### **Theme System**
```dart
enum AppThemeKind { light, dark, gold }

// Light Theme: Standard Material colors
// Dark Theme: Color(0xFF121212) background, 87% white text
// Gold Theme: Color(0xFFFFD700) primary, luxury aesthetic
```

### **Key UI Components**
- **NutritionProgressGrid**: 2x2 grid of macro progress bars
- **NutritionProgressBar**: Individual macro with goal tracking
- **NutritionMetricsRow**: Compact 4-chip macro display
- **PrimaryMetricCard**: Large metric display with subtitle
- **EmptyState**: Unified empty state with CTA
- **StatTile**: Reusable metric card component

### **Navigation Structure**
```
Bottom Navigation (5 tabs):
├── Dashboard (/)
├── Meals (/meals)
├── Workouts (/workouts)
├── Sleep (/sleep)
└── Settings (/settings)

Additional Routes:
├── Calendar (/calendar)
├── Meal Editor (/meals/edit)
├── Workout Session (/workouts/session)
└── Sleep Timer (/sleep/timer)
```

---

## ⚙️ Features & Functionality

### **Dashboard (3-Card Layout)**
1. **Enhanced Nutrition Card**
   - Primary metric display (user-selectable: Calories/Protein/Carbs/Fat)
   - Progress bars when goals set, chips when no goals
   - Hebrew/English localized labels
   
2. **Workouts Card**
   - Today's workout count or time spent
   - Motivational messages based on progress
   
3. **Sleep Card**
   - Last night's sleep hours
   - Quality feedback ("Well rested" / "Need more sleep")

### **Meals System**
- **Food Catalog**: Searchable database with nutrition per unit
- **Meal Logging**: Multi-item meals with quantity tracking
- **Daily Totals**: Real-time macro aggregation
- **Progress Tracking**: Visual progress bars toward nutrition goals
- **Timeframe**: Day/Week view toggle

### **Workouts System**
- **Templates**: Reusable workout plans with exercises
- **Session Tracking**: Live workout with set/rep/weight logging
- **Daily Workouts Provider**: Planned/Active/Completed categorization
- **Background Refresh**: Real-time updates without spinners
- **Compact Display**: Efficient list with status pills

### **Sleep Tracking**
- **Manual Entry**: Bedtime/wake time with quality rating
- **Sleep Timer**: Automated tracking (UI placeholder)
- **Duration Calculation**: Automatic sleep hours computation
- **Quality Metrics**: 1-5 scale with descriptive labels

### **Calendar System**
- **Multi-View**: Month/Week/Day view toggle
- **Event Integration**: Meals, workouts, sleep in unified timeline
- **Draggable Agenda**: Bottom sheet with event details
- **Weekend Highlighting**: Friday/Saturday (Israeli culture)
- **Date Distinction**: Today (outline) vs Selected (solid fill)

### **Settings & Preferences**
- **Nutrition Goals**: Individual goals for all 4 macros (Calories: 800-20,000, Macros: 10-600g)
- **Primary Metric**: User-selectable main dashboard metric
- **Timeframe Mode**: Global Day/Week preference
- **Workout Display**: Count vs Time spent
- **Theme Selection**: Light/Dark/Gold with live switching
- **Language**: Hebrew/English with RTL support
- **Validation**: Real-time input validation with Hebrew error messages

---

## 🌐 Localization & RTL

### **Supported Languages**
- **English (en)**: Left-to-right, standard layout
- **Hebrew (he)**: Right-to-left, mirrored UI elements

### **Translation Files**
- `lib/l10n/app_en.arb`: 200+ English strings
- `lib/l10n/app_he.arb`: 200+ Hebrew translations
- **Generated**: `flutter_gen/gen_l10n/app_localizations.dart`

### **RTL Adaptations**
- **Text Direction**: Automatic based on language selection
- **Layout Mirroring**: Icons, navigation, alignment
- **Number Input**: Numbers remain LTR for readability
- **Units**: Localized (kcal, grams → קק"ל, ג)

---

## 🔄 State Management Pattern

### **Riverpod Providers**
```dart
// Services
final preferencesServiceProvider = Provider<PreferencesService>
final themeServiceProvider = Provider<ThemeService>
final languageServiceProvider = Provider<LanguageService>

// Repositories
final mealsRepositoryProvider = Provider<MealsRepository>
final workoutSessionsRepositoryProvider = Provider<WorkoutSessionsRepository>
final sleepRepositoryProvider = Provider<SleepRepository>

// State Notifiers
final currentThemeProvider = StateNotifierProvider<ThemeNotifier, AppThemeKind>
final currentLanguageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>
final calendarStateProvider = StateNotifierProvider<CalendarNotifier, CalendarState>

// Stream Providers
final dailyWorkoutsProvider = StreamProvider.family<DailyWorkouts, DateTime>
```

### **Data Flow**
1. **UI Layer**: Widgets consume providers via `ref.watch()`
2. **Business Logic**: Repositories handle data operations
3. **Persistence**: Drift database + SharedPreferences
4. **State Updates**: Automatic UI rebuilds on data changes

---

## 📊 Data Models

### **Core Entities**
```dart
// Nutrition
class FoodItem { id, name, kcalPerUnit, proteinPerUnit, carbsPerUnit, fatPerUnit }
class Meal { id, name, loggedAt, items }
class DayTotals { kcal, protein, carbs, fat }

// Workouts
class WorkoutTemplate { id, name, notes, exercises }
class WorkoutSession { id, templateId, startedAt, endedAt, setEntries }
class DailyWorkouts { planned, active, completed }

// Sleep
class SleepEntry { id, bedtime, wakeTime, quality, notes }

// Calendar
class ScheduledEvent { id, title, type, scheduledAt, status }
class CalendarState { viewMode, selectedDate, focusedDate, events }
```

---

## 🚀 Build & Deployment

### **Development Setup**
```bash
# Prerequisites
flutter doctor
flutter pub get
flutter gen-l10n

# Run
flutter run -d "iPhone 15 Simulator"
flutter run --release
```

### **Code Generation**
```bash
# Database schema updates
dart run build_runner build

# Localization updates
flutter gen-l10n
```

### **Build Commands**
```bash
# iOS
flutter build ios --release
flutter build ipa

# Android
flutter build apk --release
flutter build appbundle --release
```

---

## 🧪 Testing Strategy

### **Unit Tests**
- Repository layer testing
- Business logic validation
- Data model serialization

### **Widget Tests**
- UI component behavior
- State management integration
- Navigation flow testing

### **Integration Tests**
- End-to-end user workflows
- Database operations
- Cross-platform compatibility

---

## 📈 Performance Optimizations

### **Database**
- Indexed queries for daily totals
- Efficient date-based filtering
- Lazy loading for large datasets

### **UI**
- Background refresh without spinners
- Debounced state updates (250ms)
- Efficient list rendering with `shrinkWrap`

### **Memory**
- Stream-based data loading
- Automatic provider disposal
- Optimized image handling

---

## 🔒 Data Privacy & Security

### **Local Storage Only**
- No cloud synchronization
- All data stored locally on device
- User controls all data export/import

### **Permissions**
- No network permissions required
- Local storage access only
- Optional notification permissions

---

## 🐛 Known Limitations

1. **Calendar Recurrence**: Basic implementation, no complex patterns
2. **Workout Timer**: Live session timing needs enhancement
3. **Data Export**: Manual export only, no automated backup
4. **Offline Mode**: App is offline-first but no sync capability

---

## 📋 Future Enhancements

### **Phase 2 Features**
- Cloud backup & sync
- Advanced workout analytics
- Nutrition recommendations
- Social sharing capabilities
- Apple Health / Google Fit integration

### **Technical Debt**
- Migrate to newer Drift version
- Implement proper error boundaries
- Add comprehensive logging
- Performance monitoring integration

---

## 📞 Development Notes

### **Key Design Decisions**
1. **3-Card Dashboard**: Simplified from 4 cards for better focus
2. **Hebrew-First**: Full RTL support with cultural adaptations
3. **Goal-Driven UI**: Progress bars appear only when goals are set
4. **Background Refresh**: No loading spinners, always show content
5. **Unified Components**: Consistent design system across all pages

### **Architecture Benefits**
- **Scalable**: Feature-based module organization
- **Testable**: Clear separation of concerns
- **Maintainable**: Consistent patterns and conventions
- **Localizable**: Full i18n support with RTL handling
- **Performant**: Optimized for mobile devices

---

*Last Updated: December 2024*  
*Version: 1.0.0*  
*Platform: Flutter 3.x*
