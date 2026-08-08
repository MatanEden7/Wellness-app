import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Wellness App'**
  String get appTitle;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night!'**
  String get goodNight;

  /// No description provided for @yourWellnessOverview.
  ///
  /// In en, this message translates to:
  /// **'Your wellness overview'**
  String get yourWellnessOverview;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// No description provided for @workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @todaysWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Workouts'**
  String get todaysWorkouts;

  /// No description provided for @allWorkouts.
  ///
  /// In en, this message translates to:
  /// **'All Workouts'**
  String get allWorkouts;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @logMeal.
  ///
  /// In en, this message translates to:
  /// **'Log Meal'**
  String get logMeal;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @wellRested.
  ///
  /// In en, this message translates to:
  /// **'Well rested!'**
  String get wellRested;

  /// No description provided for @needMore.
  ///
  /// In en, this message translates to:
  /// **'Need more sleep'**
  String get needMore;

  /// No description provided for @getMoving.
  ///
  /// In en, this message translates to:
  /// **'Get moving?'**
  String get getMoving;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get great;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get hebrew;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @primaryNutritionMetric.
  ///
  /// In en, this message translates to:
  /// **'Primary Metric'**
  String get primaryNutritionMetric;

  /// No description provided for @globalTimeframe.
  ///
  /// In en, this message translates to:
  /// **'Global Timeframe'**
  String get globalTimeframe;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @workoutMetricDisplay.
  ///
  /// In en, this message translates to:
  /// **'Workout Metric'**
  String get workoutMetricDisplay;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @noMealsYet.
  ///
  /// In en, this message translates to:
  /// **'No meals yet'**
  String get noMealsYet;

  /// No description provided for @addMeal.
  ///
  /// In en, this message translates to:
  /// **'Add Meal'**
  String get addMeal;

  /// No description provided for @trackYourNutrition.
  ///
  /// In en, this message translates to:
  /// **'Track your nutrition'**
  String get trackYourNutrition;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get noWorkoutsYet;

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get createTemplate;

  /// No description provided for @startYourFitness.
  ///
  /// In en, this message translates to:
  /// **'Start your fitness journey'**
  String get startYourFitness;

  /// No description provided for @noSleepYet.
  ///
  /// In en, this message translates to:
  /// **'No sleep yet'**
  String get noSleepYet;

  /// No description provided for @logSleep.
  ///
  /// In en, this message translates to:
  /// **'Log Sleep'**
  String get logSleep;

  /// No description provided for @trackYourRest.
  ///
  /// In en, this message translates to:
  /// **'Track your rest'**
  String get trackYourRest;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @grams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get grams;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @addFood.
  ///
  /// In en, this message translates to:
  /// **'Add Food'**
  String get addFood;

  /// No description provided for @foodName.
  ///
  /// In en, this message translates to:
  /// **'Food Name'**
  String get foodName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @workoutTemplates.
  ///
  /// In en, this message translates to:
  /// **'Workout Templates'**
  String get workoutTemplates;

  /// No description provided for @recentWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Recent Workouts'**
  String get recentWorkouts;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @deleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get deleteTemplate;

  /// No description provided for @deleteTemplateConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{templateName}\"?'**
  String deleteTemplateConfirmation(Object templateName);

  /// No description provided for @quickWorkout.
  ///
  /// In en, this message translates to:
  /// **'Quick Workout'**
  String get quickWorkout;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Export all your data to a JSON file'**
  String get exportDataDescription;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// Settings toggle: include app data in iCloud/Google device backups
  ///
  /// In en, this message translates to:
  /// **'Device Backup'**
  String get cloudBackup;

  /// No description provided for @cloudBackupOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is included in iCloud backups'**
  String get cloudBackupOnSubtitle;

  /// No description provided for @cloudBackupOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Excluded from backups — export manually to keep a copy'**
  String get cloudBackupOffSubtitle;

  /// No description provided for @cloudBackupOnSubtitleAndroid.
  ///
  /// In en, this message translates to:
  /// **'Your data is included in Google backups'**
  String get cloudBackupOnSubtitleAndroid;

  /// No description provided for @backupSettingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Backup setting updated'**
  String get backupSettingUpdated;

  /// No description provided for @importDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Import data from a JSON file'**
  String get importDataDescription;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @weightUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight Unit'**
  String get weightUnit;

  /// No description provided for @kilograms.
  ///
  /// In en, this message translates to:
  /// **'Kilograms (kg)'**
  String get kilograms;

  /// No description provided for @dailyCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Calorie Goal'**
  String get dailyCalorieGoal;

  /// No description provided for @dailyProteinGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Protein Goal'**
  String get dailyProteinGoal;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'1.0.0'**
  String get appVersion;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @dataExportedTo.
  ///
  /// In en, this message translates to:
  /// **'Data exported to {filePath}'**
  String dataExportedTo(Object filePath);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @importDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will replace all your current data. Are you sure you want to continue?'**
  String get importDataConfirmation;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @filePickerNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'File picker not implemented in this demo'**
  String get filePickerNotImplemented;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon!'**
  String get featureComingSoon;

  /// No description provided for @showNumberOfWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Show number of workouts completed'**
  String get showNumberOfWorkouts;

  /// No description provided for @showTotalMinutes.
  ///
  /// In en, this message translates to:
  /// **'Show total minutes spent exercising'**
  String get showTotalMinutes;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @timeTo.
  ///
  /// In en, this message translates to:
  /// **'Time to'**
  String get timeTo;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @caloriesShort.
  ///
  /// In en, this message translates to:
  /// **'Cal'**
  String get caloriesShort;

  /// No description provided for @proteinShort.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get proteinShort;

  /// No description provided for @carbsShort.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get carbsShort;

  /// No description provided for @fatShort.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get fatShort;

  /// No description provided for @timeSpent.
  ///
  /// In en, this message translates to:
  /// **'Time Spent'**
  String get timeSpent;

  /// No description provided for @workoutCount.
  ///
  /// In en, this message translates to:
  /// **'Workout Count'**
  String get workoutCount;

  /// No description provided for @weekStart.
  ///
  /// In en, this message translates to:
  /// **'Week Start'**
  String get weekStart;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @weekendDays.
  ///
  /// In en, this message translates to:
  /// **'Weekend Days'**
  String get weekendDays;

  /// No description provided for @fridaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Friday & Saturday'**
  String get fridaySaturday;

  /// No description provided for @saturdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Saturday & Sunday'**
  String get saturdaySunday;

  /// No description provided for @defaultTimes.
  ///
  /// In en, this message translates to:
  /// **'Default Times'**
  String get defaultTimes;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @workoutTime.
  ///
  /// In en, this message translates to:
  /// **'Workout Time'**
  String get workoutTime;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @sleepReminder.
  ///
  /// In en, this message translates to:
  /// **'Sleep Reminder'**
  String get sleepReminder;

  /// No description provided for @workoutReminder.
  ///
  /// In en, this message translates to:
  /// **'Workout Reminder'**
  String get workoutReminder;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @meal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get meal;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @sleepEntry.
  ///
  /// In en, this message translates to:
  /// **'Sleep Entry'**
  String get sleepEntry;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @mondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// No description provided for @saturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// No description provided for @sundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;

  /// No description provided for @nutritionGoals.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Goals'**
  String get nutritionGoals;

  /// No description provided for @calorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Calorie Goal'**
  String get calorieGoal;

  /// No description provided for @proteinGoal.
  ///
  /// In en, this message translates to:
  /// **'Protein Goal'**
  String get proteinGoal;

  /// No description provided for @carbsGoal.
  ///
  /// In en, this message translates to:
  /// **'Carbs Goal'**
  String get carbsGoal;

  /// No description provided for @fatGoal.
  ///
  /// In en, this message translates to:
  /// **'Fat Goal'**
  String get fatGoal;

  /// No description provided for @goalValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value between {min} and {max}'**
  String goalValidationError(Object max, Object min);

  /// No description provided for @dashboardTab.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTab;

  /// No description provided for @mealsTab.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get mealsTab;

  /// No description provided for @workoutsTab.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutsTab;

  /// No description provided for @sleepTab.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @monthView.
  ///
  /// In en, this message translates to:
  /// **'Month View'**
  String get monthView;

  /// No description provided for @weekView.
  ///
  /// In en, this message translates to:
  /// **'Week View'**
  String get weekView;

  /// No description provided for @dayView.
  ///
  /// In en, this message translates to:
  /// **'Day View'**
  String get dayView;

  /// No description provided for @showPlanned.
  ///
  /// In en, this message translates to:
  /// **'Show Planned'**
  String get showPlanned;

  /// No description provided for @showCompleted.
  ///
  /// In en, this message translates to:
  /// **'Show Completed'**
  String get showCompleted;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @eventSchedulingDialog.
  ///
  /// In en, this message translates to:
  /// **'Event scheduling dialog will be implemented next.'**
  String get eventSchedulingDialog;

  /// No description provided for @eventEditingDialog.
  ///
  /// In en, this message translates to:
  /// **'Event editing dialog will be implemented next.'**
  String get eventEditingDialog;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @calendarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTooltip;

  /// No description provided for @backToDashboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboardTooltip;

  /// No description provided for @addEventTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEventTooltip;

  /// No description provided for @foodCatalogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Food Catalog'**
  String get foodCatalogTooltip;

  /// No description provided for @mealTemplates.
  ///
  /// In en, this message translates to:
  /// **'Meal Templates'**
  String get mealTemplates;

  /// No description provided for @createMealTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Meal Template'**
  String get createMealTemplate;

  /// No description provided for @editMealTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit Meal Template'**
  String get editMealTemplate;

  /// No description provided for @noMealTemplates.
  ///
  /// In en, this message translates to:
  /// **'No meal templates yet'**
  String get noMealTemplates;

  /// No description provided for @createMealTemplateToReuse.
  ///
  /// In en, this message translates to:
  /// **'Create meal templates to quickly reuse your favorite meals'**
  String get createMealTemplateToReuse;

  /// No description provided for @createFirstMealTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create First Template'**
  String get createFirstMealTemplate;

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get templateName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @foodItems.
  ///
  /// In en, this message translates to:
  /// **'Food Items'**
  String get foodItems;

  /// No description provided for @addFoodsToTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add Foods to Template'**
  String get addFoodsToTemplate;

  /// No description provided for @selectFoodsFromYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select foods from your library to include in this template'**
  String get selectFoodsFromYourLibrary;

  /// No description provided for @pleaseEnterTemplateName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a template name'**
  String get pleaseEnterTemplateName;

  /// No description provided for @pleaseAddAtLeastOneFood.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one food item'**
  String get pleaseAddAtLeastOneFood;

  /// No description provided for @mealTemplateSaved.
  ///
  /// In en, this message translates to:
  /// **'Meal template saved'**
  String get mealTemplateSaved;

  /// No description provided for @mealCreatedFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'Meal created from template'**
  String get mealCreatedFromTemplate;

  /// No description provided for @useNow.
  ///
  /// In en, this message translates to:
  /// **'Use Now'**
  String get useNow;

  /// No description provided for @logNewMeal.
  ///
  /// In en, this message translates to:
  /// **'Log New Meal'**
  String get logNewMeal;

  /// No description provided for @createMealFromScratch.
  ///
  /// In en, this message translates to:
  /// **'Create a new meal from scratch'**
  String get createMealFromScratch;

  /// No description provided for @useTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use Template'**
  String get useTemplate;

  /// No description provided for @chooseSavedMealTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose from saved meal templates'**
  String get chooseSavedMealTemplate;

  /// No description provided for @noFoodsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No foods available. Create some foods first.'**
  String get noFoodsAvailable;

  /// No description provided for @selectFood.
  ///
  /// In en, this message translates to:
  /// **'Select Food'**
  String get selectFood;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @addFoodTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Food'**
  String get addFoodTooltip;

  /// No description provided for @addSleepEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Sleep Entry'**
  String get addSleepEntryTooltip;

  /// No description provided for @finishWorkoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Finish Workout'**
  String get finishWorkoutTooltip;

  /// No description provided for @addExerciseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExerciseTooltip;

  /// No description provided for @brandOptional.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get brandOptional;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesLabel;

  /// No description provided for @proteinGrams.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get proteinGrams;

  /// No description provided for @carbsGrams.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get carbsGrams;

  /// No description provided for @fatGrams.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get fatGrams;

  /// No description provided for @bedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get bedtime;

  /// No description provided for @wakeTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'Wake Time (optional)'**
  String get wakeTimeOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @mealTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'Time (optional)'**
  String get mealTimeOptional;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @exerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseName;

  /// No description provided for @primaryMuscleOptional.
  ///
  /// In en, this message translates to:
  /// **'Primary Muscle (optional)'**
  String get primaryMuscleOptional;

  /// No description provided for @mealName.
  ///
  /// In en, this message translates to:
  /// **'Meal Name'**
  String get mealName;

  /// No description provided for @searchFoods.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get searchFoods;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @defaultSets.
  ///
  /// In en, this message translates to:
  /// **'Default Sets'**
  String get defaultSets;

  /// No description provided for @defaultRepsOptional.
  ///
  /// In en, this message translates to:
  /// **'Default Reps (optional)'**
  String get defaultRepsOptional;

  /// No description provided for @defaultRestOptional.
  ///
  /// In en, this message translates to:
  /// **'Rest between sets (seconds)'**
  String get defaultRestOptional;

  /// No description provided for @defaultWeightOptional.
  ///
  /// In en, this message translates to:
  /// **'Default Weight (optional)'**
  String get defaultWeightOptional;

  /// No description provided for @sleepStartTime.
  ///
  /// In en, this message translates to:
  /// **'Sleep Start Time'**
  String get sleepStartTime;

  /// No description provided for @deleteFood.
  ///
  /// In en, this message translates to:
  /// **'Delete Food'**
  String get deleteFood;

  /// No description provided for @finishWorkout.
  ///
  /// In en, this message translates to:
  /// **'Finish Workout'**
  String get finishWorkout;

  /// No description provided for @deleteExercise.
  ///
  /// In en, this message translates to:
  /// **'Delete Exercise'**
  String get deleteExercise;

  /// No description provided for @sleepComplete.
  ///
  /// In en, this message translates to:
  /// **'Sleep Complete!'**
  String get sleepComplete;

  /// No description provided for @deleteFoodConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteFoodConfirmation(Object name);

  /// No description provided for @finishWorkoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish this workout?'**
  String get finishWorkoutConfirmation;

  /// No description provided for @deleteExerciseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteExerciseConfirmation(Object name);

  /// No description provided for @kilogramsKg.
  ///
  /// In en, this message translates to:
  /// **'Kilograms (kg)'**
  String get kilogramsKg;

  /// No description provided for @poundsLb.
  ///
  /// In en, this message translates to:
  /// **'Pounds (lb)'**
  String get poundsLb;

  /// No description provided for @bodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get bodyweight;

  /// No description provided for @pleaseEnterMealName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a meal name'**
  String get pleaseEnterMealName;

  /// No description provided for @pleaseAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one exercise'**
  String get pleaseAddExercise;

  /// No description provided for @pleaseEnterBedtime.
  ///
  /// In en, this message translates to:
  /// **'Please enter a bedtime'**
  String get pleaseEnterBedtime;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @foodCatalog.
  ///
  /// In en, this message translates to:
  /// **'Food Catalog'**
  String get foodCatalog;

  /// No description provided for @exerciseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Exercise Library'**
  String get exerciseLibrary;

  /// No description provided for @yourFoods.
  ///
  /// In en, this message translates to:
  /// **'Your Foods'**
  String get yourFoods;

  /// No description provided for @starterList.
  ///
  /// In en, this message translates to:
  /// **'Starter List'**
  String get starterList;

  /// No description provided for @editFood.
  ///
  /// In en, this message translates to:
  /// **'Edit Food'**
  String get editFood;

  /// No description provided for @createWorkoutTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Workout Template'**
  String get createWorkoutTemplate;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExercise;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @sleepTracking.
  ///
  /// In en, this message translates to:
  /// **'Sleep Tracking'**
  String get sleepTracking;

  /// No description provided for @wakeTime.
  ///
  /// In en, this message translates to:
  /// **'Wake Time'**
  String get wakeTime;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @lbs.
  ///
  /// In en, this message translates to:
  /// **'lbs'**
  String get lbs;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @dailyTotals.
  ///
  /// In en, this message translates to:
  /// **'Daily Totals'**
  String get dailyTotals;

  /// No description provided for @fuelUp.
  ///
  /// In en, this message translates to:
  /// **'fuel up'**
  String get fuelUp;

  /// No description provided for @trackYourNutritionFor.
  ///
  /// In en, this message translates to:
  /// **'Track your nutrition for'**
  String get trackYourNutritionFor;

  /// No description provided for @logFirstMeal.
  ///
  /// In en, this message translates to:
  /// **'Log First Meal'**
  String get logFirstMeal;

  /// No description provided for @designYourWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Design your workouts'**
  String get designYourWorkouts;

  /// No description provided for @createFirstTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create First Template'**
  String get createFirstTemplate;

  /// No description provided for @yourFitnessJourneyAwaits.
  ///
  /// In en, this message translates to:
  /// **'Your fitness journey awaits'**
  String get yourFitnessJourneyAwaits;

  /// No description provided for @completeWorkoutsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Complete workouts will appear here'**
  String get completeWorkoutsWillAppear;

  /// No description provided for @startQuickWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Quick Workout'**
  String get startQuickWorkout;

  /// No description provided for @sweetDreamsAwait.
  ///
  /// In en, this message translates to:
  /// **'Sweet dreams await'**
  String get sweetDreamsAwait;

  /// No description provided for @trackSleepForInsights.
  ///
  /// In en, this message translates to:
  /// **'Track your sleep for better rest insights'**
  String get trackSleepForInsights;

  /// No description provided for @startSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Start Sleep Timer'**
  String get startSleepTimer;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @addMealsWorkoutsSleep.
  ///
  /// In en, this message translates to:
  /// **'Add meals, workouts, or sleep for this day'**
  String get addMealsWorkoutsSleep;

  /// No description provided for @getMovingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Get moving?'**
  String get getMovingQuestion;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noDataAvailable;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View Calendar'**
  String get viewCalendar;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete Confirmation'**
  String get deleteConfirmation;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get thisActionCannotBeUndone;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @deleteWorkout.
  ///
  /// In en, this message translates to:
  /// **'Delete Workout'**
  String get deleteWorkout;

  /// No description provided for @deleteMeal.
  ///
  /// In en, this message translates to:
  /// **'Delete Meal'**
  String get deleteMeal;

  /// No description provided for @deleteSleep.
  ///
  /// In en, this message translates to:
  /// **'Delete Sleep Entry'**
  String get deleteSleep;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @cleanAndBright.
  ///
  /// In en, this message translates to:
  /// **'Clean and bright interface'**
  String get cleanAndBright;

  /// No description provided for @easyOnEyes.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes in low light'**
  String get easyOnEyes;

  /// No description provided for @luxuryGold.
  ///
  /// In en, this message translates to:
  /// **'Luxury gold accents on dark background'**
  String get luxuryGold;

  /// No description provided for @leftToRight.
  ///
  /// In en, this message translates to:
  /// **'Left-to-right text'**
  String get leftToRight;

  /// No description provided for @rightToLeft.
  ///
  /// In en, this message translates to:
  /// **'Right-to-left text'**
  String get rightToLeft;

  /// No description provided for @pounds.
  ///
  /// In en, this message translates to:
  /// **'Pounds (lbs)'**
  String get pounds;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get removeItem;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @servingSize.
  ///
  /// In en, this message translates to:
  /// **'Serving Size'**
  String get servingSize;

  /// No description provided for @totalCalories.
  ///
  /// In en, this message translates to:
  /// **'Total Calories'**
  String get totalCalories;

  /// No description provided for @macronutrients.
  ///
  /// In en, this message translates to:
  /// **'Macronutrients'**
  String get macronutrients;

  /// No description provided for @workoutName.
  ///
  /// In en, this message translates to:
  /// **'Workout Name'**
  String get workoutName;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSet;

  /// No description provided for @removeSet.
  ///
  /// In en, this message translates to:
  /// **'Remove Set'**
  String get removeSet;

  /// No description provided for @restTime.
  ///
  /// In en, this message translates to:
  /// **'Rest Time'**
  String get restTime;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @sleepDuration.
  ///
  /// In en, this message translates to:
  /// **'Sleep Duration'**
  String get sleepDuration;

  /// No description provided for @sleepQuality.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality'**
  String get sleepQuality;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get veryGood;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @startTimer.
  ///
  /// In en, this message translates to:
  /// **'Start Timer'**
  String get startTimer;

  /// No description provided for @stopTimer.
  ///
  /// In en, this message translates to:
  /// **'Stop Timer'**
  String get stopTimer;

  /// No description provided for @pauseTimer.
  ///
  /// In en, this message translates to:
  /// **'Pause Timer'**
  String get pauseTimer;

  /// No description provided for @resumeTimer.
  ///
  /// In en, this message translates to:
  /// **'Resume Timer'**
  String get resumeTimer;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @viewMode.
  ///
  /// In en, this message translates to:
  /// **'View Mode'**
  String get viewMode;

  /// No description provided for @agenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get agenda;

  /// No description provided for @noEventsPlanned.
  ///
  /// In en, this message translates to:
  /// **'No events planned'**
  String get noEventsPlanned;

  /// No description provided for @noEventsForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No events for this day'**
  String get noEventsForThisDay;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get eventType;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @tooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get tooShort;

  /// No description provided for @tooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get tooLong;

  /// No description provided for @enterValue.
  ///
  /// In en, this message translates to:
  /// **'Enter value'**
  String get enterValue;

  /// No description provided for @selectOption.
  ///
  /// In en, this message translates to:
  /// **'Select option'**
  String get selectOption;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noStarterFoodsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No starter foods available'**
  String get noStarterFoodsAvailable;

  /// No description provided for @buildYourFoodLibrary.
  ///
  /// In en, this message translates to:
  /// **'Build your food library'**
  String get buildYourFoodLibrary;

  /// No description provided for @starterFoodsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Starter foods will appear here once loaded'**
  String get starterFoodsWillAppear;

  /// No description provided for @createCustomFoods.
  ///
  /// In en, this message translates to:
  /// **'Create custom foods for quick meal logging'**
  String get createCustomFoods;

  /// No description provided for @addFirstFood.
  ///
  /// In en, this message translates to:
  /// **'Add First Food'**
  String get addFirstFood;

  /// No description provided for @nutritionPer.
  ///
  /// In en, this message translates to:
  /// **'Nutrition per {unit}:'**
  String nutritionPer(Object unit);

  /// No description provided for @unitDefault.
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get unitDefault;

  /// No description provided for @workoutSession.
  ///
  /// In en, this message translates to:
  /// **'Workout Session'**
  String get workoutSession;

  /// No description provided for @addExercisesToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add exercises to get started'**
  String get addExercisesToGetStarted;

  /// No description provided for @completeSet.
  ///
  /// In en, this message translates to:
  /// **'Complete Set'**
  String get completeSet;

  /// No description provided for @restTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get restTimer;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @buildYourExerciseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Build your exercise library'**
  String get buildYourExerciseLibrary;

  /// No description provided for @addExercisesToCreateWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Add exercises to create custom workouts'**
  String get addExercisesToCreateWorkouts;

  /// No description provided for @addFirstExercise.
  ///
  /// In en, this message translates to:
  /// **'Add First Exercise'**
  String get addFirstExercise;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @mealsNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified for scheduled meals'**
  String get mealsNotificationDesc;

  /// No description provided for @workoutsNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified for scheduled workouts'**
  String get workoutsNotificationDesc;

  /// No description provided for @sleepNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified for bedtime and sleep tracking'**
  String get sleepNotificationDesc;

  /// No description provided for @reminderTiming.
  ///
  /// In en, this message translates to:
  /// **'Reminder Timing'**
  String get reminderTiming;

  /// No description provided for @mealReminders.
  ///
  /// In en, this message translates to:
  /// **'Meal Reminders'**
  String get mealReminders;

  /// No description provided for @workoutReminders.
  ///
  /// In en, this message translates to:
  /// **'Workout Reminders'**
  String get workoutReminders;

  /// No description provided for @sleepReminders.
  ///
  /// In en, this message translates to:
  /// **'Sleep Reminders'**
  String get sleepReminders;

  /// No description provided for @atTime.
  ///
  /// In en, this message translates to:
  /// **'At scheduled time'**
  String get atTime;

  /// No description provided for @fiveMinBefore.
  ///
  /// In en, this message translates to:
  /// **'5 minutes before'**
  String get fiveMinBefore;

  /// No description provided for @tenMinBefore.
  ///
  /// In en, this message translates to:
  /// **'10 minutes before'**
  String get tenMinBefore;

  /// No description provided for @fifteenMinBefore.
  ///
  /// In en, this message translates to:
  /// **'15 minutes before'**
  String get fifteenMinBefore;

  /// No description provided for @thirtyMinBefore.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get thirtyMinBefore;

  /// No description provided for @xMinBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String xMinBefore(int minutes);

  /// No description provided for @sleepSettings.
  ///
  /// In en, this message translates to:
  /// **'Sleep Settings'**
  String get sleepSettings;

  /// No description provided for @sleepGoal.
  ///
  /// In en, this message translates to:
  /// **'Sleep Goal'**
  String get sleepGoal;

  /// No description provided for @sleepLogReminder.
  ///
  /// In en, this message translates to:
  /// **'Sleep Log Reminder'**
  String get sleepLogReminder;

  /// No description provided for @sleepLogReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind me at {time} if I didn\'t log sleep'**
  String sleepLogReminderDesc(String time);

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get quietHours;

  /// No description provided for @quietHoursDesc.
  ///
  /// In en, this message translates to:
  /// **'Don\'t send notifications during these hours'**
  String get quietHoursDesc;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @soundDesc.
  ///
  /// In en, this message translates to:
  /// **'Play sound for notifications'**
  String get soundDesc;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Vibrate for notifications'**
  String get vibrationDesc;

  /// No description provided for @scheduleEvent.
  ///
  /// In en, this message translates to:
  /// **'Schedule Event'**
  String get scheduleEvent;

  /// No description provided for @selectMealTemplate.
  ///
  /// In en, this message translates to:
  /// **'Meal Template (Optional)'**
  String get selectMealTemplate;

  /// No description provided for @selectWorkoutTemplate.
  ///
  /// In en, this message translates to:
  /// **'Workout Template (Optional)'**
  String get selectWorkoutTemplate;

  /// No description provided for @noWorkoutTemplates.
  ///
  /// In en, this message translates to:
  /// **'No workout templates yet'**
  String get noWorkoutTemplates;

  /// No description provided for @selectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select a template'**
  String get selectTemplate;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @noRepeat.
  ///
  /// In en, this message translates to:
  /// **'No Repeat'**
  String get noRepeat;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @selectDays.
  ///
  /// In en, this message translates to:
  /// **'Select days'**
  String get selectDays;

  /// No description provided for @every.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get every;

  /// No description provided for @hasEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get hasEndDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @mealReminderNotification.
  ///
  /// In en, this message translates to:
  /// **'Time for {meal}!'**
  String mealReminderNotification(String meal);

  /// No description provided for @mealReminderBodyNotification.
  ///
  /// In en, this message translates to:
  /// **'Your scheduled meal: {meal}'**
  String mealReminderBodyNotification(String meal);

  /// No description provided for @workoutReminderNotification.
  ///
  /// In en, this message translates to:
  /// **'Time to workout!'**
  String get workoutReminderNotification;

  /// No description provided for @workoutReminderBodyNotification.
  ///
  /// In en, this message translates to:
  /// **'Ready for {workout}?'**
  String workoutReminderBodyNotification(String workout);

  /// No description provided for @sleepReminderNotification.
  ///
  /// In en, this message translates to:
  /// **'Time for bed'**
  String get sleepReminderNotification;

  /// No description provided for @sleepReminderBodyNotification.
  ///
  /// In en, this message translates to:
  /// **'Get ready for a good night\'s sleep'**
  String get sleepReminderBodyNotification;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get onboardingWelcome;

  /// No description provided for @onboardingChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language to get started'**
  String get onboardingChooseLanguage;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get onboardingSex;

  /// No description provided for @onboardingMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get onboardingMale;

  /// No description provided for @onboardingFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get onboardingFemale;

  /// No description provided for @onboardingAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get onboardingAge;

  /// No description provided for @onboardingYears.
  ///
  /// In en, this message translates to:
  /// **'yr'**
  String get onboardingYears;

  /// No description provided for @onboardingHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get onboardingHeight;

  /// No description provided for @onboardingWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get onboardingWeight;

  /// No description provided for @onboardingPreferredUnits.
  ///
  /// In en, this message translates to:
  /// **'Preferred Units'**
  String get onboardingPreferredUnits;

  /// No description provided for @onboardingEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get onboardingEnergy;

  /// No description provided for @onboardingWeightUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get onboardingWeightUnit;

  /// No description provided for @onboardingGoal.
  ///
  /// In en, this message translates to:
  /// **'What\'s your goal?'**
  String get onboardingGoal;

  /// No description provided for @onboardingGoalFatLoss.
  ///
  /// In en, this message translates to:
  /// **'Fat Loss'**
  String get onboardingGoalFatLoss;

  /// No description provided for @onboardingGoalMuscleBuild.
  ///
  /// In en, this message translates to:
  /// **'Muscle Gain'**
  String get onboardingGoalMuscleBuild;

  /// No description provided for @onboardingGoalMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get onboardingGoalMaintenance;

  /// No description provided for @onboardingGoalMobilityRehab.
  ///
  /// In en, this message translates to:
  /// **'Mobility & Rehab'**
  String get onboardingGoalMobilityRehab;

  /// No description provided for @onboardingActivityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get onboardingActivityLevel;

  /// No description provided for @onboardingActivitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get onboardingActivitySedentary;

  /// No description provided for @onboardingActivityLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get onboardingActivityLight;

  /// No description provided for @onboardingActivityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get onboardingActivityModerate;

  /// No description provided for @onboardingActivityActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get onboardingActivityActive;

  /// No description provided for @onboardingActivityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very Active'**
  String get onboardingActivityVeryActive;

  /// No description provided for @onboardingTrainingDays.
  ///
  /// In en, this message translates to:
  /// **'Training Days per Week'**
  String get onboardingTrainingDays;

  /// No description provided for @onboardingDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get onboardingDays;

  /// No description provided for @onboardingEquipment.
  ///
  /// In en, this message translates to:
  /// **'Available Equipment'**
  String get onboardingEquipment;

  /// No description provided for @onboardingEquipmentNone.
  ///
  /// In en, this message translates to:
  /// **'No Equipment'**
  String get onboardingEquipmentNone;

  /// No description provided for @onboardingEquipmentDumbbells.
  ///
  /// In en, this message translates to:
  /// **'Dumbbells'**
  String get onboardingEquipmentDumbbells;

  /// No description provided for @onboardingEquipmentBarbell.
  ///
  /// In en, this message translates to:
  /// **'Barbell & Rack'**
  String get onboardingEquipmentBarbell;

  /// No description provided for @onboardingEquipmentMachines.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get onboardingEquipmentMachines;

  /// No description provided for @onboardingEquipmentBands.
  ///
  /// In en, this message translates to:
  /// **'Resistance Bands'**
  String get onboardingEquipmentBands;

  /// No description provided for @onboardingEquipmentKettlebells.
  ///
  /// In en, this message translates to:
  /// **'Kettlebells'**
  String get onboardingEquipmentKettlebells;

  /// No description provided for @onboardingEquipmentCable.
  ///
  /// In en, this message translates to:
  /// **'Cable Machine'**
  String get onboardingEquipmentCable;

  /// No description provided for @onboardingEquipmentPullup.
  ///
  /// In en, this message translates to:
  /// **'Pull-up Bar'**
  String get onboardingEquipmentPullup;

  /// No description provided for @onboardingDietType.
  ///
  /// In en, this message translates to:
  /// **'Diet Type'**
  String get onboardingDietType;

  /// No description provided for @onboardingDietOmnivore.
  ///
  /// In en, this message translates to:
  /// **'Omnivore'**
  String get onboardingDietOmnivore;

  /// No description provided for @onboardingDietCarnivore.
  ///
  /// In en, this message translates to:
  /// **'Carnivore'**
  String get onboardingDietCarnivore;

  /// No description provided for @onboardingDietHerbivore.
  ///
  /// In en, this message translates to:
  /// **'Plant-based'**
  String get onboardingDietHerbivore;

  /// No description provided for @onboardingMealsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Meals per Day'**
  String get onboardingMealsPerDay;

  /// No description provided for @onboardingMeals2.
  ///
  /// In en, this message translates to:
  /// **'2 Meals'**
  String get onboardingMeals2;

  /// No description provided for @onboardingMeals3.
  ///
  /// In en, this message translates to:
  /// **'3 Meals'**
  String get onboardingMeals3;

  /// No description provided for @onboardingMeals4.
  ///
  /// In en, this message translates to:
  /// **'4 Meals'**
  String get onboardingMeals4;

  /// No description provided for @onboardingMealsIF.
  ///
  /// In en, this message translates to:
  /// **'Intermittent Fasting 16:8'**
  String get onboardingMealsIF;

  /// No description provided for @onboardingExclusions.
  ///
  /// In en, this message translates to:
  /// **'Food Exclusions'**
  String get onboardingExclusions;

  /// No description provided for @onboardingExclusionsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get onboardingExclusionsNone;

  /// No description provided for @onboardingExclusionsDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get onboardingExclusionsDairy;

  /// No description provided for @onboardingExclusionsGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten'**
  String get onboardingExclusionsGluten;

  /// No description provided for @onboardingExclusionsNuts.
  ///
  /// In en, this message translates to:
  /// **'Nuts'**
  String get onboardingExclusionsNuts;

  /// No description provided for @onboardingExclusionsEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get onboardingExclusionsEggs;

  /// No description provided for @onboardingExclusionsShellfish.
  ///
  /// In en, this message translates to:
  /// **'Shellfish'**
  String get onboardingExclusionsShellfish;

  /// No description provided for @onboardingExclusionsSoy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get onboardingExclusionsSoy;

  /// No description provided for @onboardingInjuries.
  ///
  /// In en, this message translates to:
  /// **'Any Injuries?'**
  String get onboardingInjuries;

  /// No description provided for @onboardingInjuriesNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get onboardingInjuriesNone;

  /// No description provided for @onboardingInjuriesShoulder.
  ///
  /// In en, this message translates to:
  /// **'Shoulder'**
  String get onboardingInjuriesShoulder;

  /// No description provided for @onboardingInjuriesBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingInjuriesBack;

  /// No description provided for @onboardingInjuriesKnee.
  ///
  /// In en, this message translates to:
  /// **'Knee'**
  String get onboardingInjuriesKnee;

  /// No description provided for @onboardingInjuriesAnkle.
  ///
  /// In en, this message translates to:
  /// **'Ankle'**
  String get onboardingInjuriesAnkle;

  /// No description provided for @onboardingInjuriesElbow.
  ///
  /// In en, this message translates to:
  /// **'Elbow'**
  String get onboardingInjuriesElbow;

  /// No description provided for @onboardingInjuriesHip.
  ///
  /// In en, this message translates to:
  /// **'Hip'**
  String get onboardingInjuriesHip;

  /// No description provided for @onboardingInjuriesNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get onboardingInjuriesNeck;

  /// No description provided for @onboardingBuildScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up my full schedule'**
  String get onboardingBuildScheduleTitle;

  /// No description provided for @onboardingBuildScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add recurring workout, meal and sleep events to your calendar, built from your answers'**
  String get onboardingBuildScheduleSubtitle;

  /// No description provided for @onboardingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your personalized plan'**
  String get onboardingSummaryTitle;

  /// No description provided for @onboardingSummaryTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily Target'**
  String get onboardingSummaryTarget;

  /// No description provided for @onboardingComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get onboardingComplete;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your primary goal?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your activity level?'**
  String get onboardingActivityTitle;

  /// No description provided for @onboardingExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Training experience'**
  String get onboardingExperienceTitle;

  /// No description provided for @onboardingExperienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long you\'ve been lifting — this sets your starting weights.'**
  String get onboardingExperienceSubtitle;

  /// No description provided for @onboardingExperienceBeginner.
  ///
  /// In en, this message translates to:
  /// **'New to lifting'**
  String get onboardingExperienceBeginner;

  /// No description provided for @onboardingExperienceIntermediate.
  ///
  /// In en, this message translates to:
  /// **'A year or two'**
  String get onboardingExperienceIntermediate;

  /// No description provided for @onboardingExperienceAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Several years'**
  String get onboardingExperienceAdvanced;

  /// No description provided for @onboardingTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'How many training days per week?'**
  String get onboardingTrainingTitle;

  /// No description provided for @onboardingEquipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'What equipment do you have?'**
  String get onboardingEquipmentTitle;

  /// No description provided for @onboardingDietTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your diet type?'**
  String get onboardingDietTitle;

  /// No description provided for @onboardingMealsTitle.
  ///
  /// In en, this message translates to:
  /// **'How many meals per day?'**
  String get onboardingMealsTitle;

  /// No description provided for @onboardingExclusionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Any food exclusions?'**
  String get onboardingExclusionsTitle;

  /// No description provided for @onboardingInjuriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Any injuries to work around?'**
  String get onboardingInjuriesTitle;

  /// No description provided for @onboardingBMR.
  ///
  /// In en, this message translates to:
  /// **'BMR'**
  String get onboardingBMR;

  /// No description provided for @onboardingTDEE.
  ///
  /// In en, this message translates to:
  /// **'TDEE'**
  String get onboardingTDEE;

  /// No description provided for @onboardingGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get onboardingGoalLabel;

  /// No description provided for @restTimerCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest Complete!'**
  String get restTimerCompleteTitle;

  /// No description provided for @restTimerCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Time to continue with {exercise}'**
  String restTimerCompleteBody(String exercise);

  /// No description provided for @sleepGoalReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep Goal Reached!'**
  String get sleepGoalReachedTitle;

  /// No description provided for @sleepGoalReachedBody.
  ///
  /// In en, this message translates to:
  /// **'You slept {hours} hours -- that\'s your goal.'**
  String sleepGoalReachedBody(String hours);

  /// No description provided for @sleepStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} night streak'**
  String sleepStreakLabel(int count);

  /// No description provided for @deleteOldData.
  ///
  /// In en, this message translates to:
  /// **'Delete Old Data'**
  String get deleteOldData;

  /// No description provided for @deleteOldDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Free up space by removing old logged meals, workouts, and sleep entries'**
  String get deleteOldDataDescription;

  /// No description provided for @olderThanNDays.
  ///
  /// In en, this message translates to:
  /// **'Older than {days} days'**
  String olderThanNDays(int days);

  /// No description provided for @deleteOldDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes logged meals, workouts, and sleep entries older than {days} days. This cannot be undone.'**
  String deleteOldDataConfirmation(int days);

  /// No description provided for @deleteOldDataResult.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} old entries'**
  String deleteOldDataResult(int count);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @muteSound.
  ///
  /// In en, this message translates to:
  /// **'Mute sound'**
  String get muteSound;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @customizeSectionColors.
  ///
  /// In en, this message translates to:
  /// **'Customize section colors'**
  String get customizeSectionColors;

  /// No description provided for @customizeThemeAndColors.
  ///
  /// In en, this message translates to:
  /// **'Customize theme and section colors'**
  String get customizeThemeAndColors;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @sectionColors.
  ///
  /// In en, this message translates to:
  /// **'Section Colors'**
  String get sectionColors;

  /// No description provided for @nutritionColors.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Colors'**
  String get nutritionColors;

  /// No description provided for @followTheme.
  ///
  /// In en, this message translates to:
  /// **'Follow Theme'**
  String get followTheme;

  /// No description provided for @followThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use theme color for all nutrition metrics'**
  String get followThemeDesc;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @resetAllData.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get resetAllData;

  /// No description provided for @resetAllDataDone.
  ///
  /// In en, this message translates to:
  /// **'All data has been reset. Starting fresh.'**
  String get resetAllDataDone;

  /// No description provided for @resetThemeColors.
  ///
  /// In en, this message translates to:
  /// **'Reset Theme Colors'**
  String get resetThemeColors;

  /// No description provided for @resetSectionColors.
  ///
  /// In en, this message translates to:
  /// **'Reset Section Colors'**
  String get resetSectionColors;

  /// No description provided for @resetNutritionColors.
  ///
  /// In en, this message translates to:
  /// **'Reset Nutrition Colors'**
  String get resetNutritionColors;

  /// No description provided for @resetAllColors.
  ///
  /// In en, this message translates to:
  /// **'Reset All Colors'**
  String get resetAllColors;

  /// No description provided for @primaryButton.
  ///
  /// In en, this message translates to:
  /// **'Primary Button'**
  String get primaryButton;

  /// No description provided for @fiveMin.
  ///
  /// In en, this message translates to:
  /// **'5min'**
  String get fiveMin;

  /// No description provided for @nutritionMetricsThemeColorLabel.
  ///
  /// In en, this message translates to:
  /// **'All nutrition metrics will use this theme color:'**
  String get nutritionMetricsThemeColorLabel;

  /// No description provided for @completedSets.
  ///
  /// In en, this message translates to:
  /// **'Completed Sets'**
  String get completedSets;

  /// No description provided for @currentColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentColorLabel;

  /// No description provided for @customizeSectionColorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Customize colors for each section:'**
  String get customizeSectionColorsLabel;

  /// No description provided for @customizeIndividualColorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Customize individual colors:'**
  String get customizeIndividualColorsLabel;

  /// No description provided for @dailyOverview.
  ///
  /// In en, this message translates to:
  /// **'Daily Overview'**
  String get dailyOverview;

  /// No description provided for @dailyTargets.
  ///
  /// In en, this message translates to:
  /// **'Daily Targets'**
  String get dailyTargets;

  /// No description provided for @defaultRestTime.
  ///
  /// In en, this message translates to:
  /// **'Default Rest Time'**
  String get defaultRestTime;

  /// No description provided for @workoutTimerHint.
  ///
  /// In en, this message translates to:
  /// **'During workouts, you can mute the timer using the volume button and add extra rest time as needed.'**
  String get workoutTimerHint;

  /// No description provided for @editSleepSession.
  ///
  /// In en, this message translates to:
  /// **'Edit Sleep Session'**
  String get editSleepSession;

  /// No description provided for @eventsAndActivities.
  ///
  /// In en, this message translates to:
  /// **'Events & Activities'**
  String get eventsAndActivities;

  /// No description provided for @exerciseComplete.
  ///
  /// In en, this message translates to:
  /// **'Exercise Complete!'**
  String get exerciseComplete;

  /// No description provided for @exerciseSettings.
  ///
  /// In en, this message translates to:
  /// **'Exercise Settings'**
  String get exerciseSettings;

  /// No description provided for @onboardingSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what we calculated for you'**
  String get onboardingSummarySubtitle;

  /// No description provided for @hexCode.
  ///
  /// In en, this message translates to:
  /// **'Hex Code'**
  String get hexCode;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @metabolicInfo.
  ///
  /// In en, this message translates to:
  /// **'Metabolic Info'**
  String get metabolicInfo;

  /// No description provided for @nextExercise.
  ///
  /// In en, this message translates to:
  /// **'Next Exercise'**
  String get nextExercise;

  /// No description provided for @noRecentMeals.
  ///
  /// In en, this message translates to:
  /// **'No recent meals'**
  String get noRecentMeals;

  /// No description provided for @noRecentWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No recent workouts'**
  String get noRecentWorkouts;

  /// No description provided for @nutritionTotals.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Totals'**
  String get nutritionTotals;

  /// No description provided for @pasteJsonExportLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste your JSON export data below:'**
  String get pasteJsonExportLabel;

  /// No description provided for @timerSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play sound when rest timer completes'**
  String get timerSoundSubtitle;

  /// No description provided for @preciseControls.
  ///
  /// In en, this message translates to:
  /// **'Precise Controls'**
  String get preciseControls;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @repsUppercase.
  ///
  /// In en, this message translates to:
  /// **'REPS'**
  String get repsUppercase;

  /// No description provided for @restTimerUppercase.
  ///
  /// In en, this message translates to:
  /// **'REST TIMER'**
  String get restTimerUppercase;

  /// No description provided for @rgbValues.
  ///
  /// In en, this message translates to:
  /// **'RGB Values'**
  String get rgbValues;

  /// No description provided for @readyForSleep.
  ///
  /// In en, this message translates to:
  /// **'Ready for Sleep?'**
  String get readyForSleep;

  /// No description provided for @saturationAndBrightness.
  ///
  /// In en, this message translates to:
  /// **'Saturation & Brightness'**
  String get saturationAndBrightness;

  /// No description provided for @selectExercise.
  ///
  /// In en, this message translates to:
  /// **'Select Exercise'**
  String get selectExercise;

  /// No description provided for @selectFoodItem.
  ///
  /// In en, this message translates to:
  /// **'Select Food Item'**
  String get selectFoodItem;

  /// No description provided for @selectAllThatApply.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply'**
  String get selectAllThatApply;

  /// No description provided for @sleepQualityOptional.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality (optional)'**
  String get sleepQualityOptional;

  /// No description provided for @sleepingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Sleeping...'**
  String get sleepingEllipsis;

  /// No description provided for @readyForSleepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to start tracking your sleep'**
  String get readyForSleepSubtitle;

  /// No description provided for @resetDataWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete all your meals, workouts, sleep entries, and custom foods/exercises.\n\nTheme settings will be preserved.\n\nThis action cannot be undone!'**
  String get resetDataWarningBody;

  /// No description provided for @resetColorsWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This will reset all custom colors to their defaults. This action cannot be undone.'**
  String get resetColorsWarningBody;

  /// No description provided for @timeBetweenSets.
  ///
  /// In en, this message translates to:
  /// **'Time between sets'**
  String get timeBetweenSets;

  /// No description provided for @timerSound.
  ///
  /// In en, this message translates to:
  /// **'Timer Sound'**
  String get timerSound;

  /// No description provided for @timerVolume.
  ///
  /// In en, this message translates to:
  /// **'Timer Volume'**
  String get timerVolume;

  /// No description provided for @onboardingInjuriesHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll suggest appropriate rehab exercises'**
  String get onboardingInjuriesHint;

  /// No description provided for @onboardingGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What are your goals?'**
  String get onboardingGoalsTitle;

  /// No description provided for @workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete!'**
  String get workoutComplete;

  /// No description provided for @workoutSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Settings'**
  String get workoutSettingsTitle;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get analyticsRangeWeek;

  /// No description provided for @analyticsRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get analyticsRangeMonth;

  /// No description provided for @analyticsRangeSixMonths.
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get analyticsRangeSixMonths;

  /// No description provided for @analyticsRangeYear.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get analyticsRangeYear;

  /// No description provided for @analyticsGoalsReached.
  ///
  /// In en, this message translates to:
  /// **'Goals reached'**
  String get analyticsGoalsReached;

  /// No description provided for @analyticsInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get analyticsInsights;

  /// No description provided for @analyticsTrainingVolume.
  ///
  /// In en, this message translates to:
  /// **'Training volume'**
  String get analyticsTrainingVolume;

  /// No description provided for @analyticsStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get analyticsStrength;

  /// No description provided for @analyticsBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get analyticsBodyWeight;

  /// No description provided for @analyticsBodyWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'Body weight trend'**
  String get analyticsBodyWeightTrend;

  /// No description provided for @analyticsSetsByMuscle.
  ///
  /// In en, this message translates to:
  /// **'Sets by muscle'**
  String get analyticsSetsByMuscle;

  /// No description provided for @analyticsWorkingWeight.
  ///
  /// In en, this message translates to:
  /// **'Working weight'**
  String get analyticsWorkingWeight;

  /// No description provided for @analyticsGoalTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get analyticsGoalTraining;

  /// No description provided for @analyticsGoalTrainingShort.
  ///
  /// In en, this message translates to:
  /// **'training'**
  String get analyticsGoalTrainingShort;

  /// No description provided for @analyticsGoalCaloriesShort.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get analyticsGoalCaloriesShort;

  /// No description provided for @analyticsGoalProteinShort.
  ///
  /// In en, this message translates to:
  /// **'protein'**
  String get analyticsGoalProteinShort;

  /// No description provided for @analyticsGoalSleepShort.
  ///
  /// In en, this message translates to:
  /// **'sleep'**
  String get analyticsGoalSleepShort;

  /// No description provided for @analyticsAvgKcal.
  ///
  /// In en, this message translates to:
  /// **'Avg kcal'**
  String get analyticsAvgKcal;

  /// No description provided for @analyticsAvgProtein.
  ///
  /// In en, this message translates to:
  /// **'Avg protein'**
  String get analyticsAvgProtein;

  /// No description provided for @analyticsDaysLogged.
  ///
  /// In en, this message translates to:
  /// **'Days logged'**
  String get analyticsDaysLogged;

  /// No description provided for @analyticsSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get analyticsSessions;

  /// No description provided for @analyticsPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get analyticsPerWeek;

  /// No description provided for @analyticsTimeSpent.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get analyticsTimeSpent;

  /// No description provided for @analyticsNights.
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get analyticsNights;

  /// No description provided for @analyticsBedtimeSwing.
  ///
  /// In en, this message translates to:
  /// **'Bedtime swing'**
  String get analyticsBedtimeSwing;

  /// No description provided for @analyticsLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get analyticsLatest;

  /// No description provided for @analyticsChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get analyticsChange;

  /// No description provided for @analyticsLogWeight.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get analyticsLogWeight;

  /// No description provided for @analyticsOtherMuscle.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get analyticsOtherMuscle;

  /// No description provided for @analyticsBodyweightLabel.
  ///
  /// In en, this message translates to:
  /// **'bodyweight'**
  String get analyticsBodyweightLabel;

  /// No description provided for @analyticsStrengthLegend.
  ///
  /// In en, this message translates to:
  /// **'Line: estimated 1RM · dots: heaviest set'**
  String get analyticsStrengthLegend;

  /// No description provided for @analyticsStreakDay.
  ///
  /// In en, this message translates to:
  /// **'1 day streak'**
  String get analyticsStreakDay;

  /// No description provided for @analyticsStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String analyticsStreakDays(String days);

  /// No description provided for @analyticsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'best {days}'**
  String analyticsBestStreak(String days);

  /// No description provided for @analyticsAvgValue.
  ///
  /// In en, this message translates to:
  /// **'{value} avg'**
  String analyticsAvgValue(String value);

  /// No description provided for @analyticsBestE1rm.
  ///
  /// In en, this message translates to:
  /// **'{value} best e1RM'**
  String analyticsBestE1rm(String value);

  /// No description provided for @analyticsTotalVolume.
  ///
  /// In en, this message translates to:
  /// **'{value} kg total'**
  String analyticsTotalVolume(String value);

  /// No description provided for @analyticsVolumeValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kg'**
  String analyticsVolumeValue(String value);

  /// No description provided for @analyticsPerWeekOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{actual} / {target}'**
  String analyticsPerWeekOfTarget(String actual, String target);

  /// No description provided for @analyticsDaysLoggedValue.
  ///
  /// In en, this message translates to:
  /// **'{logged}/{total}'**
  String analyticsDaysLoggedValue(String logged, String total);

  /// No description provided for @analyticsTopSet.
  ///
  /// In en, this message translates to:
  /// **'{weight} × {reps}'**
  String analyticsTopSet(String weight, String reps);

  /// No description provided for @analyticsSessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String analyticsSessionCount(String count);

  /// No description provided for @analyticsWeekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String analyticsWeekOf(String date);

  /// No description provided for @analyticsEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged in this range yet.\nLog a meal, a workout or a night of sleep and this fills in.'**
  String get analyticsEmptyAll;

  /// No description provided for @analyticsEmptyGoals.
  ///
  /// In en, this message translates to:
  /// **'Set a calorie or protein goal to start scoring your days.'**
  String get analyticsEmptyGoals;

  /// No description provided for @analyticsEmptyMeals.
  ///
  /// In en, this message translates to:
  /// **'No meals logged in this range.'**
  String get analyticsEmptyMeals;

  /// No description provided for @analyticsEmptyWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No completed workouts in this range.'**
  String get analyticsEmptyWorkouts;

  /// No description provided for @analyticsEmptySleep.
  ///
  /// In en, this message translates to:
  /// **'No completed sleep entries in this range.'**
  String get analyticsEmptySleep;

  /// No description provided for @analyticsEmptyStrength.
  ///
  /// In en, this message translates to:
  /// **'Log a few sets to see your progression.'**
  String get analyticsEmptyStrength;

  /// No description provided for @analyticsEmptyWeighIns.
  ///
  /// In en, this message translates to:
  /// **'No weigh-ins yet. One a week is enough to see a trend.'**
  String get analyticsEmptyWeighIns;

  /// No description provided for @analyticsBodyweightOnlyExercise.
  ///
  /// In en, this message translates to:
  /// **'This exercise is bodyweight only — there is no load to chart.'**
  String get analyticsBodyweightOnlyExercise;

  /// No description provided for @analyticsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your analytics.\n{error}'**
  String analyticsLoadError(String error);

  /// No description provided for @analyticsWeightSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weight'**
  String get analyticsWeightSheetTitle;

  /// No description provided for @analyticsWeightSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replaces any earlier entry for today.'**
  String get analyticsWeightSheetSubtitle;

  /// No description provided for @analyticsWeightSheetError.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between 20 and 400 kg'**
  String get analyticsWeightSheetError;

  /// No description provided for @analyticsPlateauNewBest.
  ///
  /// In en, this message translates to:
  /// **'{weight} · new best'**
  String analyticsPlateauNewBest(String weight);

  /// No description provided for @analyticsPlateauMovedUp.
  ///
  /// In en, this message translates to:
  /// **'{weight} · moved up'**
  String analyticsPlateauMovedUp(String weight);

  /// No description provided for @analyticsPlateauStalled.
  ///
  /// In en, this message translates to:
  /// **'{weight} · {sessions} sessions · {days}d'**
  String analyticsPlateauStalled(String weight, String sessions, String days);

  /// No description provided for @insightPlateau.
  ///
  /// In en, this message translates to:
  /// **'{exercise} has stayed at {weight} for {sessions} sessions — try adding 2.5 kg or one more rep.'**
  String insightPlateau(String exercise, String weight, String sessions);

  /// No description provided for @insightPersonalBest.
  ///
  /// In en, this message translates to:
  /// **'New best on {exercise}: {value} estimated 1RM.'**
  String insightPersonalBest(String exercise, String value);

  /// No description provided for @insightProteinShortfall.
  ///
  /// In en, this message translates to:
  /// **'Protein averaged {actual} against your {goal} goal.'**
  String insightProteinShortfall(String actual, String goal);

  /// No description provided for @insightCalorieDriftHigh.
  ///
  /// In en, this message translates to:
  /// **'Calories are running {actual} a day against a {goal} goal.'**
  String insightCalorieDriftHigh(String actual, String goal);

  /// No description provided for @insightCalorieDriftLow.
  ///
  /// In en, this message translates to:
  /// **'Calories are running low: {actual} a day against a {goal} goal.'**
  String insightCalorieDriftLow(String actual, String goal);

  /// No description provided for @insightVolumeDrop.
  ///
  /// In en, this message translates to:
  /// **'Training volume is down {percent} on your recent average.'**
  String insightVolumeDrop(String percent);

  /// No description provided for @insightSleepDebt.
  ///
  /// In en, this message translates to:
  /// **'{nights} of the last 7 nights came in under {hours}.'**
  String insightSleepDebt(String nights, String hours);

  /// No description provided for @insightConsistencyWin.
  ///
  /// In en, this message translates to:
  /// **'{days} days in a row hitting every goal.'**
  String insightConsistencyWin(String days);

  /// No description provided for @insightNeglectedMuscle.
  ///
  /// In en, this message translates to:
  /// **'Only {sets} sets for {muscle} in this range.'**
  String insightNeglectedMuscle(String sets, String muscle);

  /// No description provided for @a11yChartNoData.
  ///
  /// In en, this message translates to:
  /// **'{name} chart. No data in this range.'**
  String a11yChartNoData(String name);

  /// No description provided for @a11yChartHeader.
  ///
  /// In en, this message translates to:
  /// **'{name} chart, by {period}.'**
  String a11yChartHeader(String name, String period);

  /// No description provided for @a11yChartCoverage.
  ///
  /// In en, this message translates to:
  /// **'{observed} of {total} {period} with data.'**
  String a11yChartCoverage(String observed, String total, String period);

  /// No description provided for @a11yChartAverage.
  ///
  /// In en, this message translates to:
  /// **'Average {average}, from {min} to {max}.'**
  String a11yChartAverage(String average, String min, String max);

  /// No description provided for @a11yChartGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal {goal}.'**
  String a11yChartGoal(String goal);

  /// No description provided for @a11yPeriodDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get a11yPeriodDay;

  /// No description provided for @a11yPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get a11yPeriodWeek;

  /// No description provided for @a11yPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get a11yPeriodMonth;

  /// No description provided for @a11yPeriodDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get a11yPeriodDays;

  /// No description provided for @a11yPeriodWeeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get a11yPeriodWeeks;

  /// No description provided for @a11yPeriodMonths.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get a11yPeriodMonths;

  /// No description provided for @a11yTrendFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat across the range.'**
  String get a11yTrendFlat;

  /// No description provided for @a11yTrendRoughlyFlat.
  ///
  /// In en, this message translates to:
  /// **'Roughly flat across the range.'**
  String get a11yTrendRoughlyFlat;

  /// No description provided for @a11yTrendRising.
  ///
  /// In en, this message translates to:
  /// **'Rising by about {amount} across the range.'**
  String a11yTrendRising(String amount);

  /// No description provided for @a11yTrendFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling by about {amount} across the range.'**
  String a11yTrendFalling(String amount);

  /// No description provided for @a11yGoalChartNoData.
  ///
  /// In en, this message translates to:
  /// **'Goals reached chart. No data in this range.'**
  String get a11yGoalChartNoData;

  /// No description provided for @a11yGoalChart.
  ///
  /// In en, this message translates to:
  /// **'Goals reached chart.'**
  String get a11yGoalChart;

  /// No description provided for @a11yGoalAverage.
  ///
  /// In en, this message translates to:
  /// **'Averaging {percent} of your daily goals.'**
  String a11yGoalAverage(String percent);

  /// No description provided for @a11yGoalStreakDay.
  ///
  /// In en, this message translates to:
  /// **'Current streak 1 day hitting every goal.'**
  String get a11yGoalStreakDay;

  /// No description provided for @a11yGoalStreakDays.
  ///
  /// In en, this message translates to:
  /// **'Current streak {days} days hitting every goal.'**
  String a11yGoalStreakDays(String days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
