// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wellness App';

  @override
  String get goodMorning => 'Good morning!';

  @override
  String get goodAfternoon => 'Good afternoon!';

  @override
  String get goodEvening => 'Good evening!';

  @override
  String get goodNight => 'Good night!';

  @override
  String get yourWellnessOverview => 'Your wellness overview';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get navHome => 'Home';

  @override
  String get navStats => 'Stats';

  @override
  String get meals => 'Meals';

  @override
  String get workouts => 'Workouts';

  @override
  String get sleep => 'Sleep';

  @override
  String get calendar => 'Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get todaysWorkouts => 'Today\'s Workouts';

  @override
  String get allWorkouts => 'All Workouts';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get logMeal => 'Log Meal';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get calories => 'Calories';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get nights => 'nights';

  @override
  String get wellRested => 'Well rested!';

  @override
  String get needMore => 'Need more sleep';

  @override
  String get getMoving => 'Get moving?';

  @override
  String get great => 'Great job!';

  @override
  String get noData => 'No data';

  @override
  String get planned => 'Planned';

  @override
  String get active => 'Active';

  @override
  String get done => 'Done';

  @override
  String get resume => 'Resume';

  @override
  String get refresh => 'Refresh';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'Hebrew';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get gold => 'Gold';

  @override
  String get primaryNutritionMetric => 'Primary Metric';

  @override
  String get globalTimeframe => 'Global Timeframe';

  @override
  String get day => 'Day';

  @override
  String get week => 'Week';

  @override
  String get workoutMetricDisplay => 'Workout Metric';

  @override
  String get time => 'Time';

  @override
  String get count => 'Count';

  @override
  String get noMealsYet => 'No meals yet';

  @override
  String get addMeal => 'Add Meal';

  @override
  String get trackYourNutrition => 'Track your nutrition';

  @override
  String get noWorkoutsYet => 'No workouts yet';

  @override
  String get createTemplate => 'Create Template';

  @override
  String get startYourFitness => 'Start your fitness journey';

  @override
  String get noSleepYet => 'No sleep yet';

  @override
  String get logSleep => 'Log Sleep';

  @override
  String get trackYourRest => 'Track your rest';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get grams => 'g';

  @override
  String get hours => 'hours';

  @override
  String get minutes => 'minutes';

  @override
  String get kcal => 'kcal';

  @override
  String get centimetersShort => 'cm';

  @override
  String get addFood => 'Add Food';

  @override
  String get foodName => 'Food Name';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get workoutTemplates => 'Workout Templates';

  @override
  String get recentWorkouts => 'Recent Workouts';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String deleteTemplateConfirmation(Object templateName) {
    return 'Are you sure you want to delete \"$templateName\"?';
  }

  @override
  String get quickWorkout => 'Quick Workout';

  @override
  String get duration => 'Duration';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataDescription => 'Export all your data to a JSON file';

  @override
  String get importData => 'Import Data';

  @override
  String get cloudBackup => 'Device Backup';

  @override
  String get cloudBackupOnSubtitle => 'Your data is included in iCloud backups';

  @override
  String get cloudBackupOffSubtitle =>
      'Excluded from backups — export manually to keep a copy';

  @override
  String get cloudBackupOnSubtitleAndroid =>
      'Your data is included in Google backups';

  @override
  String get backupSettingUpdated => 'Backup setting updated';

  @override
  String get importDataDescription => 'Import data from a JSON file';

  @override
  String get preferences => 'Preferences';

  @override
  String get weightUnit => 'Weight Unit';

  @override
  String get kilograms => 'Kilograms (kg)';

  @override
  String get dailyCalorieGoal => 'Daily Calorie Goal';

  @override
  String get dailyProteinGoal => 'Daily Protein Goal';

  @override
  String get notSet => 'Not set';

  @override
  String get about => 'About';

  @override
  String get appVersion => '1.0.0';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String dataExportedTo(Object filePath) {
    return 'Data exported to $filePath';
  }

  @override
  String exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get importDataConfirmation =>
      'This will replace all your current data. Are you sure you want to continue?';

  @override
  String get import => 'Import';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get filePickerNotImplemented =>
      'File picker not implemented in this demo';

  @override
  String get featureComingSoon => 'This feature is coming soon!';

  @override
  String get showNumberOfWorkouts => 'Show number of workouts completed';

  @override
  String get showTotalMinutes => 'Show total minutes spent exercising';

  @override
  String get today => 'Today';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get timeTo => 'Time to';

  @override
  String get change => 'Change';

  @override
  String get inProgress => 'In Progress';

  @override
  String get caloriesShort => 'Cal';

  @override
  String get proteinShort => 'P';

  @override
  String get carbsShort => 'C';

  @override
  String get fatShort => 'F';

  @override
  String get timeSpent => 'Time Spent';

  @override
  String get workoutCount => 'Workout Count';

  @override
  String get weekStart => 'Week Start';

  @override
  String get sunday => 'Sunday';

  @override
  String get monday => 'Monday';

  @override
  String get weekendDays => 'Weekend Days';

  @override
  String get fridaySaturday => 'Friday & Saturday';

  @override
  String get saturdaySunday => 'Saturday & Sunday';

  @override
  String get defaultTimes => 'Default Times';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get workoutTime => 'Workout Time';

  @override
  String get notifications => 'Notifications';

  @override
  String get sleepReminder => 'Sleep Reminder';

  @override
  String get workoutReminder => 'Workout Reminder';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get meal => 'Meal';

  @override
  String get workout => 'Workout';

  @override
  String get sleepEntry => 'Sleep Entry';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get mondayShort => 'Mon';

  @override
  String get tuesdayShort => 'Tue';

  @override
  String get wednesdayShort => 'Wed';

  @override
  String get thursdayShort => 'Thu';

  @override
  String get fridayShort => 'Fri';

  @override
  String get saturdayShort => 'Sat';

  @override
  String get sundayShort => 'Sun';

  @override
  String get nutritionGoals => 'Nutrition Goals';

  @override
  String get calorieGoal => 'Calorie Goal';

  @override
  String get proteinGoal => 'Protein Goal';

  @override
  String get carbsGoal => 'Carbs Goal';

  @override
  String get fatGoal => 'Fat Goal';

  @override
  String goalValidationError(Object max, Object min) {
    return 'Please enter a value between $min and $max';
  }

  @override
  String get dashboardTab => 'Dashboard';

  @override
  String get mealsTab => 'Meals';

  @override
  String get workoutsTab => 'Workouts';

  @override
  String get sleepTab => 'Sleep';

  @override
  String get settingsTab => 'Settings';

  @override
  String get monthView => 'Month View';

  @override
  String get weekView => 'Week View';

  @override
  String get dayView => 'Day View';

  @override
  String get showPlanned => 'Show Planned';

  @override
  String get showCompleted => 'Show Completed';

  @override
  String get addEvent => 'Add Event';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get markComplete => 'Mark Complete';

  @override
  String get eventSchedulingDialog =>
      'Event scheduling dialog will be implemented next.';

  @override
  String get eventEditingDialog =>
      'Event editing dialog will be implemented next.';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get calendarTooltip => 'Calendar';

  @override
  String get backToDashboardTooltip => 'Back to Dashboard';

  @override
  String get addEventTooltip => 'Add Event';

  @override
  String get foodCatalogTooltip => 'Food Catalog';

  @override
  String get mealTemplates => 'Meal Templates';

  @override
  String get createMealTemplate => 'Create Meal Template';

  @override
  String get editMealTemplate => 'Edit Meal Template';

  @override
  String get noMealTemplates => 'No meal templates yet';

  @override
  String get createMealTemplateToReuse =>
      'Create meal templates to quickly reuse your favorite meals';

  @override
  String get createFirstMealTemplate => 'Create First Template';

  @override
  String get templateName => 'Template Name';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get foodItems => 'Food Items';

  @override
  String get addFoodsToTemplate => 'Add Foods to Template';

  @override
  String get selectFoodsFromYourLibrary =>
      'Select foods from your library to include in this template';

  @override
  String get pleaseEnterTemplateName => 'Please enter a template name';

  @override
  String get pleaseAddAtLeastOneFood => 'Please add at least one food item';

  @override
  String get mealTemplateSaved => 'Meal template saved';

  @override
  String get mealCreatedFromTemplate => 'Meal created from template';

  @override
  String get useNow => 'Use Now';

  @override
  String get logNewMeal => 'Log New Meal';

  @override
  String get createMealFromScratch => 'Create a new meal from scratch';

  @override
  String get useTemplate => 'Use Template';

  @override
  String get chooseSavedMealTemplate => 'Choose from saved meal templates';

  @override
  String get noFoodsAvailable => 'No foods available. Create some foods first.';

  @override
  String get selectFood => 'Select Food';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get addFoodTooltip => 'Add Food';

  @override
  String get addSleepEntryTooltip => 'Add Sleep Entry';

  @override
  String get finishWorkoutTooltip => 'Finish Workout';

  @override
  String get addExerciseTooltip => 'Add Exercise';

  @override
  String get brandOptional => 'Brand (optional)';

  @override
  String get unit => 'Unit';

  @override
  String get caloriesLabel => 'Calories';

  @override
  String get proteinGrams => 'Protein (g)';

  @override
  String get carbsGrams => 'Carbs (g)';

  @override
  String get fatGrams => 'Fat (g)';

  @override
  String get bedtime => 'Bedtime';

  @override
  String get wakeTimeOptional => 'Wake Time (optional)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get mealTimeOptional => 'Time (optional)';

  @override
  String get reps => 'Reps';

  @override
  String get exerciseName => 'Exercise Name';

  @override
  String get primaryMuscleOptional => 'Primary Muscle (optional)';

  @override
  String get mealName => 'Meal Name';

  @override
  String get categoryAll => 'All';

  @override
  String get searchFoods => 'Search foods';

  @override
  String get amount => 'Amount';

  @override
  String get defaultSets => 'Default Sets';

  @override
  String get defaultRepsOptional => 'Default Reps (optional)';

  @override
  String get defaultRestOptional => 'Rest between sets (seconds)';

  @override
  String get defaultWeightOptional => 'Default Weight (optional)';

  @override
  String get sleepStartTime => 'Sleep Start Time';

  @override
  String get deleteFood => 'Delete Food';

  @override
  String get finishWorkout => 'Finish Workout';

  @override
  String get deleteExercise => 'Delete Exercise';

  @override
  String get sleepComplete => 'Sleep Complete!';

  @override
  String deleteFoodConfirmation(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get finishWorkoutConfirmation =>
      'Are you sure you want to finish this workout?';

  @override
  String deleteExerciseConfirmation(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get kilogramsKg => 'Kilograms (kg)';

  @override
  String get poundsLb => 'Pounds (lb)';

  @override
  String get bodyweight => 'Bodyweight';

  @override
  String get pleaseEnterMealName => 'Please enter a meal name';

  @override
  String get pleaseAddExercise => 'Please add at least one exercise';

  @override
  String get pleaseEnterBedtime => 'Please enter a bedtime';

  @override
  String get finish => 'Finish';

  @override
  String get ok => 'OK';

  @override
  String get foodCatalog => 'Food Catalog';

  @override
  String get exerciseLibrary => 'Exercise Library';

  @override
  String get yourFoods => 'Your Foods';

  @override
  String get starterList => 'Starter List';

  @override
  String get editFood => 'Edit Food';

  @override
  String get createWorkoutTemplate => 'Create Workout Template';

  @override
  String get exercises => 'Exercises';

  @override
  String get addExercise => 'Add Exercise';

  @override
  String get sets => 'Sets';

  @override
  String get weight => 'Weight';

  @override
  String get sleepTracking => 'Sleep Tracking';

  @override
  String get wakeTime => 'Wake Time';

  @override
  String get quality => 'Quality';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get good => 'Good';

  @override
  String get average => 'Average';

  @override
  String get poor => 'Poor';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'lbs';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get notes => 'Notes';

  @override
  String get dailyTotals => 'Daily Totals';

  @override
  String get fuelUp => 'fuel up';

  @override
  String get trackYourNutritionFor => 'Track your nutrition for';

  @override
  String get logFirstMeal => 'Log First Meal';

  @override
  String get designYourWorkouts => 'Design your workouts';

  @override
  String get createFirstTemplate => 'Create First Template';

  @override
  String get yourFitnessJourneyAwaits => 'Your fitness journey awaits';

  @override
  String get completeWorkoutsWillAppear => 'Complete workouts will appear here';

  @override
  String get startQuickWorkout => 'Start Quick Workout';

  @override
  String get sweetDreamsAwait => 'Sweet dreams await';

  @override
  String get trackSleepForInsights =>
      'Track your sleep for better rest insights';

  @override
  String get startSleepTimer => 'Start Sleep Timer';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get addMealsWorkoutsSleep =>
      'Add meals, workouts, or sleep for this day';

  @override
  String get getMovingQuestion => 'Get moving?';

  @override
  String get noDataAvailable => 'No data';

  @override
  String get viewAll => 'View All';

  @override
  String get viewCalendar => 'View Calendar';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get skip => 'Skip';

  @override
  String get retry => 'Retry';

  @override
  String get deleteConfirmation => 'Delete Confirmation';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String get deleteWorkout => 'Delete Workout';

  @override
  String get deleteMeal => 'Delete Meal';

  @override
  String get deleteSleep => 'Delete Sleep Entry';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get cleanAndBright => 'Clean and bright interface';

  @override
  String get easyOnEyes => 'Easy on the eyes in low light';

  @override
  String get luxuryGold => 'Luxury gold accents on dark background';

  @override
  String get leftToRight => 'Left-to-right text';

  @override
  String get rightToLeft => 'Right-to-left text';

  @override
  String get pounds => 'Pounds (lbs)';

  @override
  String get addItem => 'Add Item';

  @override
  String get removeItem => 'Remove Item';

  @override
  String get quantity => 'Quantity';

  @override
  String get servingSize => 'Serving Size';

  @override
  String get totalCalories => 'Total Calories';

  @override
  String get macronutrients => 'Macronutrients';

  @override
  String get workoutName => 'Workout Name';

  @override
  String get addSet => 'Add Set';

  @override
  String get removeSet => 'Remove Set';

  @override
  String get restTime => 'Rest Time';

  @override
  String get totalTime => 'Total Time';

  @override
  String get completed => 'Completed';

  @override
  String get notStarted => 'Not Started';

  @override
  String get sleepDuration => 'Sleep Duration';

  @override
  String get sleepQuality => 'Sleep Quality';

  @override
  String get excellent => 'Excellent';

  @override
  String get veryGood => 'Very Good';

  @override
  String get fair => 'Fair';

  @override
  String get startTimer => 'Start Timer';

  @override
  String get stopTimer => 'Stop Timer';

  @override
  String get pauseTimer => 'Pause Timer';

  @override
  String get resumeTimer => 'Resume Timer';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get viewMode => 'View Mode';

  @override
  String get agenda => 'Agenda';

  @override
  String get noEventsPlanned => 'No events planned';

  @override
  String get noEventsForThisDay => 'No events for this day';

  @override
  String get eventDetails => 'Event Details';

  @override
  String get eventType => 'Event Type';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get clear => 'Clear';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get profile => 'Profile';

  @override
  String get privacy => 'Privacy';

  @override
  String get help => 'Help';

  @override
  String get feedback => 'Feedback';

  @override
  String get version => 'Version';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get sync => 'Sync';

  @override
  String get required => 'Required';

  @override
  String get optional => 'Optional';

  @override
  String get invalid => 'Invalid';

  @override
  String get tooShort => 'Too short';

  @override
  String get tooLong => 'Too long';

  @override
  String get enterValue => 'Enter value';

  @override
  String get selectOption => 'Select option';

  @override
  String get seconds => 'seconds';

  @override
  String get days => 'days';

  @override
  String get weeks => 'weeks';

  @override
  String get months => 'months';

  @override
  String get update => 'Update';

  @override
  String get add => 'Add';

  @override
  String get noStarterFoodsAvailable => 'No starter foods available';

  @override
  String get buildYourFoodLibrary => 'Build your food library';

  @override
  String get starterFoodsWillAppear =>
      'Starter foods will appear here once loaded';

  @override
  String get createCustomFoods => 'Create custom foods for quick meal logging';

  @override
  String get addFirstFood => 'Add First Food';

  @override
  String nutritionPer(Object unit) {
    return 'Nutrition per $unit:';
  }

  @override
  String get unitDefault => 'unit';

  @override
  String get workoutSession => 'Workout Session';

  @override
  String get addExercisesToGetStarted => 'Add exercises to get started';

  @override
  String get completeSet => 'Complete Set';

  @override
  String get restTimer => 'Rest Timer';

  @override
  String get pause => 'Pause';

  @override
  String get buildYourExerciseLibrary => 'Build your exercise library';

  @override
  String get addExercisesToCreateWorkouts =>
      'Add exercises to create custom workouts';

  @override
  String get addFirstExercise => 'Add First Exercise';

  @override
  String get missed => 'Missed';

  @override
  String get complete => 'Complete';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get mealsNotificationDesc => 'Get notified for scheduled meals';

  @override
  String get workoutsNotificationDesc => 'Get notified for scheduled workouts';

  @override
  String get sleepNotificationDesc =>
      'Get notified for bedtime and sleep tracking';

  @override
  String get reminderTiming => 'Reminder Timing';

  @override
  String get mealReminders => 'Meal Reminders';

  @override
  String get workoutReminders => 'Workout Reminders';

  @override
  String get sleepReminders => 'Sleep Reminders';

  @override
  String get atTime => 'At scheduled time';

  @override
  String get fiveMinBefore => '5 minutes before';

  @override
  String get tenMinBefore => '10 minutes before';

  @override
  String get fifteenMinBefore => '15 minutes before';

  @override
  String get thirtyMinBefore => '30 minutes before';

  @override
  String xMinBefore(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String get sleepSettings => 'Sleep Settings';

  @override
  String get sleepGoal => 'Sleep Goal';

  @override
  String get sleepLogReminder => 'Sleep Log Reminder';

  @override
  String sleepLogReminderDesc(String time) {
    return 'Remind me at $time if I didn\'t log sleep';
  }

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get quietHoursDesc => 'Don\'t send notifications during these hours';

  @override
  String get sound => 'Sound';

  @override
  String get soundDesc => 'Play sound for notifications';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationDesc => 'Vibrate for notifications';

  @override
  String get scheduleEvent => 'Schedule Event';

  @override
  String get selectMealTemplate => 'Meal Template (Optional)';

  @override
  String get selectWorkoutTemplate => 'Workout Template (Optional)';

  @override
  String get noWorkoutTemplates => 'No workout templates yet';

  @override
  String get selectTemplate => 'Select a template';

  @override
  String get title => 'Title';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get description => 'Description';

  @override
  String get date => 'Date';

  @override
  String get repeat => 'Repeat';

  @override
  String get schedule => 'Schedule';

  @override
  String get noRepeat => 'No Repeat';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get custom => 'Custom';

  @override
  String get selectDays => 'Select days';

  @override
  String get every => 'Every';

  @override
  String get hasEndDate => 'End date';

  @override
  String get endDate => 'End Date';

  @override
  String mealReminderNotification(String meal) {
    return 'Time for $meal!';
  }

  @override
  String mealReminderBodyNotification(String meal) {
    return 'Your scheduled meal: $meal';
  }

  @override
  String get workoutReminderNotification => 'Time to workout!';

  @override
  String workoutReminderBodyNotification(String workout) {
    return 'Ready for $workout?';
  }

  @override
  String get sleepReminderNotification => 'Time for bed';

  @override
  String get sleepReminderBodyNotification =>
      'Get ready for a good night\'s sleep';

  @override
  String get onboardingWelcome => 'Welcome!';

  @override
  String get onboardingChooseLanguage => 'Choose your language to get started';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingSex => 'Sex';

  @override
  String get onboardingMale => 'Male';

  @override
  String get onboardingFemale => 'Female';

  @override
  String get onboardingAge => 'Age';

  @override
  String get onboardingYears => 'yr';

  @override
  String get onboardingHeight => 'Height';

  @override
  String get onboardingWeight => 'Weight';

  @override
  String get onboardingPreferredUnits => 'Preferred Units';

  @override
  String get onboardingEnergy => 'Energy';

  @override
  String get onboardingWeightUnit => 'Weight';

  @override
  String get onboardingGoal => 'What\'s your goal?';

  @override
  String get onboardingGoalFatLoss => 'Fat Loss';

  @override
  String get onboardingGoalMuscleBuild => 'Muscle Gain';

  @override
  String get onboardingGoalMaintenance => 'Maintenance';

  @override
  String get onboardingGoalMobilityRehab => 'Mobility & Rehab';

  @override
  String get onboardingActivityLevel => 'Activity Level';

  @override
  String get onboardingActivitySedentary => 'Sedentary';

  @override
  String get onboardingActivityLight => 'Light';

  @override
  String get onboardingActivityModerate => 'Moderate';

  @override
  String get onboardingActivityActive => 'Active';

  @override
  String get onboardingActivityVeryActive => 'Very Active';

  @override
  String get onboardingTrainingDays => 'Training Days per Week';

  @override
  String get onboardingDays => 'days';

  @override
  String get onboardingEquipment => 'Available Equipment';

  @override
  String get onboardingEquipmentNone => 'No Equipment';

  @override
  String get onboardingEquipmentDumbbells => 'Dumbbells';

  @override
  String get onboardingEquipmentBarbell => 'Barbell & Rack';

  @override
  String get onboardingEquipmentMachines => 'Machines';

  @override
  String get onboardingEquipmentBands => 'Resistance Bands';

  @override
  String get onboardingEquipmentKettlebells => 'Kettlebells';

  @override
  String get onboardingEquipmentCable => 'Cable Machine';

  @override
  String get onboardingEquipmentPullup => 'Pull-up Bar';

  @override
  String get onboardingDietType => 'Diet Type';

  @override
  String get onboardingDietOmnivore => 'Omnivore';

  @override
  String get onboardingDietCarnivore => 'Carnivore';

  @override
  String get onboardingDietHerbivore => 'Plant-based';

  @override
  String get onboardingMealsPerDay => 'Meals per Day';

  @override
  String get onboardingMeals2 => '2 Meals';

  @override
  String get onboardingMeals3 => '3 Meals';

  @override
  String get onboardingMeals4 => '4 Meals';

  @override
  String get onboardingMealsIF => 'Intermittent Fasting 16:8';

  @override
  String get onboardingExclusions => 'Food Exclusions';

  @override
  String get onboardingExclusionsNone => 'None';

  @override
  String get onboardingExclusionsDairy => 'Dairy';

  @override
  String get onboardingExclusionsGluten => 'Gluten';

  @override
  String get onboardingExclusionsNuts => 'Nuts';

  @override
  String get onboardingExclusionsEggs => 'Eggs';

  @override
  String get onboardingExclusionsShellfish => 'Shellfish';

  @override
  String get onboardingExclusionsSoy => 'Soy';

  @override
  String get onboardingInjuries => 'Any Injuries?';

  @override
  String get onboardingInjuriesNone => 'None';

  @override
  String get onboardingInjuriesShoulder => 'Shoulder';

  @override
  String get onboardingInjuriesBack => 'Back';

  @override
  String get onboardingInjuriesKnee => 'Knee';

  @override
  String get onboardingInjuriesAnkle => 'Ankle';

  @override
  String get onboardingInjuriesElbow => 'Elbow';

  @override
  String get onboardingInjuriesHip => 'Hip';

  @override
  String get onboardingInjuriesNeck => 'Neck';

  @override
  String get onboardingBuildScheduleTitle => 'Set up my full schedule';

  @override
  String get onboardingBuildScheduleSubtitle =>
      'Add recurring workout, meal and sleep events to your calendar, built from your answers';

  @override
  String get onboardingSummaryTitle => 'Your personalized plan';

  @override
  String get onboardingSummaryTarget => 'Daily Target';

  @override
  String get onboardingComplete => 'Complete Setup';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingGoalTitle => 'What\'s your primary goal?';

  @override
  String get onboardingActivityTitle => 'What\'s your activity level?';

  @override
  String get onboardingExperienceTitle => 'Training experience';

  @override
  String get onboardingExperienceSubtitle =>
      'How long you\'ve been lifting — this sets your starting weights.';

  @override
  String get onboardingExperienceBeginner => 'New to lifting';

  @override
  String get onboardingExperienceIntermediate => 'A year or two';

  @override
  String get onboardingExperienceAdvanced => 'Several years';

  @override
  String get onboardingTrainingTitle => 'How many training days per week?';

  @override
  String get onboardingEquipmentTitle => 'What equipment do you have?';

  @override
  String get onboardingDietTitle => 'What\'s your diet type?';

  @override
  String get onboardingMealsTitle => 'How many meals per day?';

  @override
  String get onboardingExclusionsTitle => 'Any food exclusions?';

  @override
  String get onboardingInjuriesTitle => 'Any injuries to work around?';

  @override
  String get onboardingBMR => 'BMR';

  @override
  String get onboardingTDEE => 'TDEE';

  @override
  String get onboardingGoalLabel => 'Goal';

  @override
  String get restTimerCompleteTitle => 'Rest Complete!';

  @override
  String restTimerCompleteBody(String exercise) {
    return 'Time to continue with $exercise';
  }

  @override
  String get sleepGoalReachedTitle => 'Sleep Goal Reached!';

  @override
  String sleepGoalReachedBody(String hours) {
    return 'You slept $hours hours -- that\'s your goal.';
  }

  @override
  String sleepStreakLabel(int count) {
    return '$count night streak';
  }

  @override
  String get deleteOldData => 'Delete Old Data';

  @override
  String get deleteOldDataDescription =>
      'Free up space by removing old logged meals, workouts, and sleep entries';

  @override
  String olderThanNDays(int days) {
    return 'Older than $days days';
  }

  @override
  String deleteOldDataConfirmation(int days) {
    return 'This permanently deletes logged meals, workouts, and sleep entries older than $days days. This cannot be undone.';
  }

  @override
  String deleteOldDataResult(int count) {
    return 'Deleted $count old entries';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get muteSound => 'Mute sound';

  @override
  String get appearance => 'Appearance';

  @override
  String get customizeSectionColors => 'Customize section colors';

  @override
  String get customizeThemeAndColors => 'Customize theme and section colors';

  @override
  String get back => 'Back';

  @override
  String get markAsCompleted => 'Mark as Completed';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get sectionColors => 'Section Colors';

  @override
  String get nutritionColors => 'Nutrition Colors';

  @override
  String get followTheme => 'Follow Theme';

  @override
  String get followThemeDesc => 'Use theme color for all nutrition metrics';

  @override
  String get templates => 'Templates';

  @override
  String get recent => 'Recent';

  @override
  String get resetAllData => 'Reset All Data';

  @override
  String get resetAllDataDone => 'All data has been reset. Starting fresh.';

  @override
  String get resetThemeColors => 'Reset Theme Colors';

  @override
  String get resetSectionColors => 'Reset Section Colors';

  @override
  String get resetNutritionColors => 'Reset Nutrition Colors';

  @override
  String get resetAllColors => 'Reset All Colors';

  @override
  String get primaryButton => 'Primary Button';

  @override
  String get fiveMin => '5min';

  @override
  String get nutritionMetricsThemeColorLabel =>
      'All nutrition metrics will use this theme color:';

  @override
  String get completedSets => 'Completed Sets';

  @override
  String get currentColorLabel => 'Current';

  @override
  String get customizeSectionColorsLabel =>
      'Customize colors for each section:';

  @override
  String get customizeIndividualColorsLabel => 'Customize individual colors:';

  @override
  String get dailyOverview => 'Daily Overview';

  @override
  String get dailyTargets => 'Daily Targets';

  @override
  String get defaultRestTime => 'Default Rest Time';

  @override
  String get workoutTimerHint =>
      'During workouts, you can mute the timer using the volume button and add extra rest time as needed.';

  @override
  String get editSleepSession => 'Edit Sleep Session';

  @override
  String get eventsAndActivities => 'Events & Activities';

  @override
  String get exerciseComplete => 'Exercise Complete!';

  @override
  String get exerciseSettings => 'Exercise Settings';

  @override
  String get onboardingSummarySubtitle => 'Here\'s what we calculated for you';

  @override
  String get hexCode => 'Hex Code';

  @override
  String get hue => 'Hue';

  @override
  String get metabolicInfo => 'Metabolic Info';

  @override
  String get nextExercise => 'Next Exercise';

  @override
  String get noRecentMeals => 'No recent meals';

  @override
  String get noRecentWorkouts => 'No recent workouts';

  @override
  String get nutritionTotals => 'Nutrition Totals';

  @override
  String get pasteJsonExportLabel => 'Paste your JSON export data below:';

  @override
  String get timerSoundSubtitle => 'Play sound when rest timer completes';

  @override
  String get preciseControls => 'Precise Controls';

  @override
  String get presets => 'Presets';

  @override
  String get preview => 'Preview';

  @override
  String get repsUppercase => 'REPS';

  @override
  String get restTimerUppercase => 'REST TIMER';

  @override
  String get rgbValues => 'RGB Values';

  @override
  String get readyForSleep => 'Ready for Sleep?';

  @override
  String get saturationAndBrightness => 'Saturation & Brightness';

  @override
  String get selectExercise => 'Select Exercise';

  @override
  String get selectFoodItem => 'Select Food Item';

  @override
  String get selectAllThatApply => 'Select all that apply';

  @override
  String get sleepQualityOptional => 'Sleep Quality (optional)';

  @override
  String get sleepingEllipsis => 'Sleeping...';

  @override
  String get readyForSleepSubtitle =>
      'Tap the button below to start tracking your sleep';

  @override
  String get resetDataWarningBody =>
      'This will delete all your meals, workouts, sleep entries, and custom foods/exercises.\n\nTheme settings will be preserved.\n\nThis action cannot be undone!';

  @override
  String get resetColorsWarningBody =>
      'This will reset all custom colors to their defaults. This action cannot be undone.';

  @override
  String get timeBetweenSets => 'Time between sets';

  @override
  String get timerSound => 'Timer Sound';

  @override
  String get timerVolume => 'Timer Volume';

  @override
  String get onboardingInjuriesHint =>
      'We\'ll suggest appropriate rehab exercises';

  @override
  String get onboardingGoalsTitle => 'What are your goals?';

  @override
  String get workoutComplete => 'Workout Complete!';

  @override
  String get workoutSettingsTitle => 'Workout Settings';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsRangeWeek => 'W';

  @override
  String get analyticsRangeMonth => 'M';

  @override
  String get analyticsRangeSixMonths => '6M';

  @override
  String get analyticsRangeYear => 'Y';

  @override
  String get analyticsGoalsReached => 'Goals reached';

  @override
  String get analyticsInsights => 'Insights';

  @override
  String get analyticsTrainingVolume => 'Training volume';

  @override
  String get analyticsStrength => 'Strength';

  @override
  String get analyticsBodyWeight => 'Body weight';

  @override
  String get analyticsBodyWeightTrend => 'Body weight trend';

  @override
  String get analyticsSetsByMuscle => 'Sets by muscle';

  @override
  String get analyticsWorkingWeight => 'Working weight';

  @override
  String get analyticsGoalTraining => 'Training';

  @override
  String get analyticsGoalTrainingShort => 'training';

  @override
  String get analyticsGoalCaloriesShort => 'kcal';

  @override
  String get analyticsGoalProteinShort => 'protein';

  @override
  String get analyticsGoalSleepShort => 'sleep';

  @override
  String get analyticsAvgKcal => 'Avg kcal';

  @override
  String get analyticsAvgProtein => 'Avg protein';

  @override
  String get analyticsDaysLogged => 'Days logged';

  @override
  String get analyticsSessions => 'Sessions';

  @override
  String get analyticsPerWeek => 'Per week';

  @override
  String get analyticsTimeSpent => 'Time';

  @override
  String get analyticsNights => 'Nights';

  @override
  String get analyticsBedtimeSwing => 'Bedtime swing';

  @override
  String get analyticsLatest => 'Latest';

  @override
  String get analyticsChange => 'Change';

  @override
  String get analyticsLogWeight => 'Log weight';

  @override
  String get analyticsOtherMuscle => 'Other';

  @override
  String get analyticsBodyweightLabel => 'bodyweight';

  @override
  String get analyticsStrengthLegend =>
      'Line: estimated 1RM · dots: heaviest set';

  @override
  String get analyticsStreakDay => '1 day streak';

  @override
  String analyticsStreakDays(String days) {
    return '$days day streak';
  }

  @override
  String analyticsBestStreak(String days) {
    return 'best $days';
  }

  @override
  String analyticsAvgValue(String value) {
    return '$value avg';
  }

  @override
  String analyticsBestE1rm(String value) {
    return '$value best e1RM';
  }

  @override
  String analyticsTotalVolume(String value) {
    return '$value kg total';
  }

  @override
  String analyticsVolumeValue(String value) {
    return '$value kg';
  }

  @override
  String analyticsPerWeekOfTarget(String actual, String target) {
    return '$actual / $target';
  }

  @override
  String analyticsDaysLoggedValue(String logged, String total) {
    return '$logged/$total';
  }

  @override
  String analyticsTopSet(String weight, String reps) {
    return '$weight × $reps';
  }

  @override
  String analyticsSessionCount(String count) {
    return '$count sessions';
  }

  @override
  String analyticsWeekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get analyticsEmptyAll =>
      'Nothing logged in this range yet.\nLog a meal, a workout or a night of sleep and this fills in.';

  @override
  String get analyticsEmptyGoals =>
      'Set a calorie or protein goal to start scoring your days.';

  @override
  String get analyticsEmptyMeals => 'No meals logged in this range.';

  @override
  String get analyticsEmptyWorkouts => 'No completed workouts in this range.';

  @override
  String get analyticsEmptySleep => 'No completed sleep entries in this range.';

  @override
  String get analyticsEmptyStrength =>
      'Log a few sets to see your progression.';

  @override
  String get analyticsEmptyWeighIns =>
      'No weigh-ins yet. One a week is enough to see a trend.';

  @override
  String get analyticsBodyweightOnlyExercise =>
      'This exercise is bodyweight only — there is no load to chart.';

  @override
  String analyticsLoadError(String error) {
    return 'Could not load your analytics.\n$error';
  }

  @override
  String get analyticsWeightSheetTitle => 'Today\'s weight';

  @override
  String get analyticsWeightSheetSubtitle =>
      'Replaces any earlier entry for today.';

  @override
  String get analyticsWeightSheetError =>
      'Enter a weight between 20 and 400 kg';

  @override
  String analyticsPlateauNewBest(String weight) {
    return '$weight · new best';
  }

  @override
  String analyticsPlateauMovedUp(String weight) {
    return '$weight · moved up';
  }

  @override
  String analyticsPlateauStalled(String weight, String sessions, String days) {
    return '$weight · $sessions sessions · ${days}d';
  }

  @override
  String insightPlateau(String exercise, String weight, String sessions) {
    return '$exercise has stayed at $weight for $sessions sessions — try adding 2.5 kg or one more rep.';
  }

  @override
  String insightPersonalBest(String exercise, String value) {
    return 'New best on $exercise: $value estimated 1RM.';
  }

  @override
  String insightProteinShortfall(String actual, String goal) {
    return 'Protein averaged $actual against your $goal goal.';
  }

  @override
  String insightCalorieDriftHigh(String actual, String goal) {
    return 'Calories are running $actual a day against a $goal goal.';
  }

  @override
  String insightCalorieDriftLow(String actual, String goal) {
    return 'Calories are running low: $actual a day against a $goal goal.';
  }

  @override
  String insightVolumeDrop(String percent) {
    return 'Training volume is down $percent on your recent average.';
  }

  @override
  String insightSleepDebt(String nights, String hours) {
    return '$nights of the last 7 nights came in under $hours.';
  }

  @override
  String insightConsistencyWin(String days) {
    return '$days days in a row hitting every goal.';
  }

  @override
  String insightNeglectedMuscle(String sets, String muscle) {
    return 'Only $sets sets for $muscle in this range.';
  }

  @override
  String a11yChartNoData(String name) {
    return '$name chart. No data in this range.';
  }

  @override
  String a11yChartHeader(String name, String period) {
    return '$name chart, by $period.';
  }

  @override
  String a11yChartCoverage(String observed, String total, String period) {
    return '$observed of $total $period with data.';
  }

  @override
  String a11yChartAverage(String average, String min, String max) {
    return 'Average $average, from $min to $max.';
  }

  @override
  String a11yChartGoal(String goal) {
    return 'Goal $goal.';
  }

  @override
  String get a11yPeriodDay => 'day';

  @override
  String get a11yPeriodWeek => 'week';

  @override
  String get a11yPeriodMonth => 'month';

  @override
  String get a11yPeriodDays => 'days';

  @override
  String get a11yPeriodWeeks => 'weeks';

  @override
  String get a11yPeriodMonths => 'months';

  @override
  String get a11yTrendFlat => 'Flat across the range.';

  @override
  String get a11yTrendRoughlyFlat => 'Roughly flat across the range.';

  @override
  String a11yTrendRising(String amount) {
    return 'Rising by about $amount across the range.';
  }

  @override
  String a11yTrendFalling(String amount) {
    return 'Falling by about $amount across the range.';
  }

  @override
  String get a11yGoalChartNoData =>
      'Goals reached chart. No data in this range.';

  @override
  String get a11yGoalChart => 'Goals reached chart.';

  @override
  String a11yGoalAverage(String percent) {
    return 'Averaging $percent of your daily goals.';
  }

  @override
  String get a11yGoalStreakDay => 'Current streak 1 day hitting every goal.';

  @override
  String a11yGoalStreakDays(String days) {
    return 'Current streak $days days hitting every goal.';
  }

  @override
  String get editSleepEntry => 'Edit Sleep Entry';

  @override
  String get startSleepAction => 'Start Sleep';

  @override
  String get wakeUpAction => 'Wake Up';

  @override
  String currentTimeLabel(String time) {
    return 'Current time: $time';
  }

  @override
  String startedAtLabel(String time) {
    return 'Started at $time';
  }

  @override
  String get lastNightLabel => 'Last Night';

  @override
  String get sleepAvgSevenNights => '7-Night Avg';

  @override
  String get streakLabel => 'Streak';

  @override
  String get sleepHistory => 'Sleep History';

  @override
  String hoursShortValue(String hours) {
    return '${hours}h';
  }

  @override
  String youSleptForHours(String hours) {
    return 'You slept for $hours hours';
  }

  @override
  String fromTimeToTime(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String get howDidYouSleep => 'How did you sleep?';

  @override
  String get howAreYouFeeling => 'How are you feeling?';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get quickAddMealSubtitle =>
      'Name it and add foods without leaving this screen';

  @override
  String exercisesCount(int count) {
    return '$count exercises';
  }

  @override
  String setsCompletedCount(int count) {
    return '$count sets completed';
  }

  @override
  String get workoutSettingsTooltip => 'Workout Settings';

  @override
  String get mealNameHint => 'e.g., Breakfast, Lunch, Dinner';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get searchExercises => 'Search exercises';

  @override
  String get noExercisesFound => 'No exercises match your search';

  @override
  String get primaryMuscle => 'Primary muscle';

  @override
  String get equipmentLabel => 'Equipment';

  @override
  String get targetSets => 'Target sets';

  @override
  String get targetReps => 'Target reps';

  @override
  String get restBetweenSets => 'Rest between sets';

  @override
  String restAutoLabel(String duration) {
    return 'Auto ($duration)';
  }

  @override
  String get restAutoExplainer =>
      'Based on your rep count. Fewer reps means heavier work and longer rest.';

  @override
  String get addToWorkout => 'Add to workout';

  @override
  String get exerciseDetails => 'Exercise details';

  @override
  String get editPrescription => 'Edit sets & rest';

  @override
  String get removeFromWorkout => 'Remove from workout';

  @override
  String quickWorkoutNamed(String date) {
    return 'Quick Workout $date';
  }

  @override
  String exerciseAddedToWorkout(String name) {
    return '$name added';
  }

  @override
  String setsAndRestSummary(int sets, String rest) {
    return '$sets sets · $rest rest';
  }

  @override
  String get noExercisesYet => 'No exercises yet';

  @override
  String get workoutExercises => 'Workout exercises';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get trackYourTrainingFor => 'Track your training for ';

  @override
  String get workoutTotals => 'Daily Training';

  @override
  String get yourExercises => 'Your Exercises';

  @override
  String get starterExercises => 'Starter Library';

  @override
  String get noExercisesMatch => 'No exercises match';

  @override
  String get editExercise => 'Edit Exercise';

  @override
  String get addFirstFoodItem => 'Add your first food item';

  @override
  String get editMeal => 'Edit Meal';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get customBreaks => 'Customize breaks';

  @override
  String get customBreaksSubtitle =>
      'Set your own rest between sets, and add breaks anywhere in the workout';

  @override
  String get autoBreaksSubtitle =>
      'Rest between sets is set automatically from the rep count';

  @override
  String get addRest => 'Add Break';

  @override
  String get restBlock => 'Break';

  @override
  String get restDuration => 'Break length';

  @override
  String get betweenSets => 'Between sets';

  @override
  String get automatic => 'Automatic';

  @override
  String get addExerciseShort => 'Exercise';

  @override
  String get addBreakShort => 'Break';

  @override
  String restDefaultHelper(String rest) {
    return 'Leave empty for this exercise’s default of $rest';
  }

  @override
  String get dashboardPeriodToday => 'Today';

  @override
  String get dashboardPeriodWeek => 'This week';

  @override
  String workoutMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get nightlyAverage => 'nightly average';

  @override
  String get glassEffect => 'Glass Effect';

  @override
  String get glassOff => 'Off';

  @override
  String get glassSubtle => 'Subtle';

  @override
  String get glassFull => 'Full';

  @override
  String get glassEffectReducedByAccessibility =>
      'Off — Reduce Transparency is on';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileNotCompleted => 'Profile setup not completed';

  @override
  String get profileSectionBody => 'Body';

  @override
  String get profileSectionGoal => 'Goal & Activity';

  @override
  String get profileSectionTargets => 'Nutrition Targets';

  @override
  String get profileSectionFood => 'Food & Diet';

  @override
  String get profileSectionUnits => 'Units';

  @override
  String get profileTrainingDaysWeek => 'Training Days / Week';

  @override
  String get profileCalorieTarget => 'Calorie Target';

  @override
  String get profileProteinTarget => 'Protein Target';

  @override
  String get profileCarbsTarget => 'Carbs Target';

  @override
  String get profileFatTarget => 'Fat Target';

  @override
  String get profileInjuries => 'Injuries';

  @override
  String get profileEnergyUnit => 'Energy Unit';

  @override
  String get profileRecalculate => 'Recalculate from Body & Goal';

  @override
  String get profileRegenTitle => 'Update your templates?';

  @override
  String get healthSection => 'Health';

  @override
  String get calendarSelectRecentMeal => 'Select a recent meal';

  @override
  String get calendarSelectRecentWorkout => 'Select a recent workout';

  @override
  String get filterShowingEverything => 'Showing everything';

  @override
  String get foodBrandHint => 'e.g., Generic, Organic, etc.';

  @override
  String get foodUnitHint => 'g, ml, piece, cup, etc.';

  @override
  String get foodTagsContains => 'Contains';

  @override
  String get foodTagsContainsHelp =>
      'Used to hide this food when it clashes with your diet or exclusions. Leave blank if it contains none.';

  @override
  String get foodTagsAnimalOrigin => 'Animal origin';

  @override
  String get foodTagsAnimalOriginHelp => 'Used for plant-based diets.';

  @override
  String get mealNotesHint => 'Any additional notes about this meal';

  @override
  String get mealTemplateNameHint =>
      'e.g., High Protein Breakfast, Pre-Workout Snack';

  @override
  String get mealTemplateNotesHint => 'Notes about this meal template';

  @override
  String get colorRolePrimary => 'Primary';

  @override
  String get colorRoleBackground => 'Background';

  @override
  String get colorRoleSurface => 'Surface';

  @override
  String get exerciseNameHint => 'e.g., Bench Press, Squats';

  @override
  String get exerciseMuscleHint => 'e.g., Chest, Legs, Back';

  @override
  String get exerciseNotesHint => 'Form cues, variations, etc.';

  @override
  String get exerciseEquipmentNeeded => 'Equipment needed';

  @override
  String get exerciseEquipmentHelp =>
      'Pick every option this can be done with. Leave blank and it will be treated as always available.';

  @override
  String get exerciseAvoidInjury => 'Avoid with injury to';

  @override
  String get exerciseAvoidInjuryHelp =>
      'This will be hidden for anyone reporting one of these injuries.';

  @override
  String get workoutTemplateNameHint => 'e.g., Push Day, Full Body';

  @override
  String get workoutTemplateNotesHint =>
      'Any notes about this workout template';

  @override
  String get templateNoExercisesAdded => 'No exercises added';

  @override
  String get templateNoExercisesHelp =>
      'Add exercises to build your workout template';

  @override
  String get templateNoExercises => 'No exercises';

  @override
  String get templateRepsEmptyHint => 'Leave empty for variable reps';

  @override
  String get workoutLoading => 'Loading workout...';

  @override
  String get sleepInProgress => 'In progress...';

  @override
  String profileRegenBody(int meals, int workouts) {
    return 'Your profile changed in a way that affects which meals and workouts suit you.\n\nRebuilding replaces $meals generated meal template(s) and $workouts generated workout template(s). Anything you created or edited yourself is kept.';
  }

  @override
  String get themeOcean => 'Ocean';

  @override
  String get themeForest => 'Forest';

  @override
  String get themeSunset => 'Sunset';

  @override
  String get themeLavender => 'Lavender';

  @override
  String get themeMidnight => 'Midnight';

  @override
  String get themeCustom => 'Custom';

  @override
  String get themeOceanDesc => 'Calming blues & teals';

  @override
  String get themeForestDesc => 'Natural & balanced greens';

  @override
  String get themeSunsetDesc => 'Warm & energetic';

  @override
  String get themeLavenderDesc => 'Mindful & creative';

  @override
  String get themeMidnightDesc => 'Sophisticated dark blue';

  @override
  String get themeCustomDesc => 'Customize your own colors';

  @override
  String get appearanceThemeColors => 'Theme Colors';

  @override
  String get appearanceSectionColors => 'Section Colors';

  @override
  String get appearanceNutritionColors => 'Nutrition Colors';

  @override
  String get appearancePreview => 'Preview';

  @override
  String get appearanceCustomAll =>
      'Customize all app colors. Changes apply immediately.';

  @override
  String get appearanceCustomSection =>
      'Customize section colors. Switch to Custom theme to edit theme colors.';

  @override
  String get tapToCompleteSetup => 'Tap to complete setup';

  @override
  String goalsSetCount(int count) {
    return '$count/4 goals set';
  }

  @override
  String perUnit(String unit) {
    return 'Per $unit:';
  }

  @override
  String nutritionPerUnit(String unit) {
    return 'Nutrition per $unit:';
  }

  @override
  String get unitPer100g => 'Nutrition values are per 100 grams';

  @override
  String get unitPerGram => 'Nutrition values are per gram';

  @override
  String get unitPerMl => 'Nutrition values are per milliliter';

  @override
  String get unitPerOz => 'Nutrition values are per ounce';

  @override
  String unitPerCount(String unit) {
    return 'Nutrition values are per $unit';
  }

  @override
  String durationHm(String h, String m) {
    return '${h}h ${m}m';
  }

  @override
  String durationM(String m) {
    return '${m}m';
  }

  @override
  String get durationLabel => 'Duration';

  @override
  String activeFor(String duration) {
    return 'Active $duration';
  }

  @override
  String get scheduled => 'Scheduled';

  @override
  String get brandGeneric => 'Generic';

  @override
  String amountWithUnit(String unit) {
    return 'Amount ($unit)';
  }
}
