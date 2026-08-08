// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'אפליקציית בריאות';

  @override
  String get goodMorning => 'בוקר טוב!';

  @override
  String get goodAfternoon => 'צהריים טובים!';

  @override
  String get goodEvening => 'ערב טוב!';

  @override
  String get goodNight => 'לילה טוב!';

  @override
  String get yourWellnessOverview => 'סקירת הבריאות שלך';

  @override
  String get dashboard => 'לוח בקרה';

  @override
  String get meals => 'ארוחות';

  @override
  String get workouts => 'אימונים';

  @override
  String get sleep => 'שינה';

  @override
  String get calendar => 'יומן';

  @override
  String get settings => 'הגדרות';

  @override
  String get todaysWorkouts => 'אימוני היום';

  @override
  String get allWorkouts => 'כל האימונים';

  @override
  String get quickActions => 'פעולות מהירות';

  @override
  String get logMeal => 'רישום ארוחה';

  @override
  String get startWorkout => 'התחל אימון';

  @override
  String get sleepTimer => 'טיימר שינה';

  @override
  String get calories => 'קלוריות';

  @override
  String get protein => 'חלבון';

  @override
  String get carbs => 'פחמימות';

  @override
  String get fat => 'שומן';

  @override
  String get wellRested => 'נח היטב!';

  @override
  String get needMore => 'צריך עוד שינה';

  @override
  String get getMoving => 'בואו נזוז?';

  @override
  String get great => 'כל הכבוד!';

  @override
  String get noData => 'אין נתונים';

  @override
  String get planned => 'מתוכנן';

  @override
  String get active => 'פעיל';

  @override
  String get done => 'הושלם';

  @override
  String get resume => 'המשך';

  @override
  String get refresh => 'רענן';

  @override
  String get language => 'שפה';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'עברית';

  @override
  String get theme => 'ערכת נושא';

  @override
  String get light => 'בהיר';

  @override
  String get dark => 'כהה';

  @override
  String get gold => 'זהב';

  @override
  String get primaryNutritionMetric => 'מדד עיקרי';

  @override
  String get globalTimeframe => 'מסגרת זמן כללית';

  @override
  String get day => 'יום';

  @override
  String get week => 'שבוע';

  @override
  String get workoutMetricDisplay => 'מדד אימון';

  @override
  String get time => 'שעה';

  @override
  String get count => 'ספירה';

  @override
  String get noMealsYet => 'עדיין אין ארוחות';

  @override
  String get addMeal => 'הוסף ארוחה';

  @override
  String get trackYourNutrition => 'עקוב אחר התזונה שלך';

  @override
  String get noWorkoutsYet => 'עדיין אין אימונים';

  @override
  String get createTemplate => 'צור תבנית';

  @override
  String get startYourFitness => 'התחל את מסע הכושר שלך';

  @override
  String get noSleepYet => 'עדיין אין שינה';

  @override
  String get logSleep => 'רשום שינה';

  @override
  String get trackYourRest => 'עקוב אחר המנוחה שלך';

  @override
  String get nutrition => 'תזונה';

  @override
  String get grams => 'ג';

  @override
  String get hours => 'שעות';

  @override
  String get minutes => 'דקות';

  @override
  String get kcal => 'קק\"ל';

  @override
  String get addFood => 'הוסף מזון';

  @override
  String get foodName => 'שם המזון';

  @override
  String get save => 'שמור';

  @override
  String get cancel => 'ביטול';

  @override
  String get edit => 'ערוך';

  @override
  String get delete => 'מחק';

  @override
  String get workoutTemplates => 'תבניות אימון';

  @override
  String get recentWorkouts => 'אימונים אחרונים';

  @override
  String get backToDashboard => 'חזרה ללוח הבקרה';

  @override
  String get deleteTemplate => 'מחק תבנית';

  @override
  String deleteTemplateConfirmation(Object templateName) {
    return 'האם אתה בטוח שברצונך למחוק את \"$templateName\"?';
  }

  @override
  String get quickWorkout => 'אימון מהיר';

  @override
  String get duration => 'משך זמן';

  @override
  String get dataManagement => 'ניהול נתונים';

  @override
  String get exportData => 'ייצא נתונים';

  @override
  String get exportDataDescription => 'ייצא את כל הנתונים שלך לקובץ JSON';

  @override
  String get importData => 'ייבא נתונים';

  @override
  String get cloudBackup => 'גיבוי המכשיר';

  @override
  String get cloudBackupOnSubtitle => 'הנתונים שלך נכללים בגיבויי iCloud';

  @override
  String get cloudBackupOffSubtitle =>
      'לא נכלל בגיבויים — ייצא ידנית כדי לשמור עותק';

  @override
  String get cloudBackupOnSubtitleAndroid =>
      'הנתונים שלך נכללים בגיבויי Google';

  @override
  String get backupSettingUpdated => 'הגדרת הגיבוי עודכנה';

  @override
  String get importDataDescription => 'ייבא נתונים מקובץ JSON';

  @override
  String get preferences => 'העדפות';

  @override
  String get weightUnit => 'יחידת משקל';

  @override
  String get kilograms => 'קילוגרמים (ק״ג)';

  @override
  String get dailyCalorieGoal => 'יעד קלוריות יומי';

  @override
  String get dailyProteinGoal => 'יעד חלבון יומי';

  @override
  String get notSet => 'לא הוגדר';

  @override
  String get about => 'אודות';

  @override
  String get appVersion => '1.0.0';

  @override
  String get privacyPolicy => 'מדיניות פרטיות';

  @override
  String get helpSupport => 'עזרה ותמיכה';

  @override
  String dataExportedTo(Object filePath) {
    return 'נתונים יוצאו אל $filePath';
  }

  @override
  String exportFailed(Object error) {
    return 'ייצוא נכשל: $error';
  }

  @override
  String get importDataConfirmation =>
      'פעולה זו תחליף את כל הנתונים הנוכחיים שלך. האם אתה בטוח שברצונך להמשיך?';

  @override
  String get import => 'ייבא';

  @override
  String get chooseFile => 'בחר קובץ';

  @override
  String get filePickerNotImplemented => 'בוחר קבצים לא מיושם בדמו זה';

  @override
  String get featureComingSoon => 'תכונה זו תגיע בקרוב!';

  @override
  String get showNumberOfWorkouts => 'הצג מספר אימונים שהושלמו';

  @override
  String get showTotalMinutes => 'הצג סך דקות אימון';

  @override
  String get today => 'היום';

  @override
  String get manualEntry => 'רישום ידני';

  @override
  String get timeTo => 'זמן';

  @override
  String get change => 'שנה';

  @override
  String get inProgress => 'בתהליך';

  @override
  String get caloriesShort => 'ק';

  @override
  String get proteinShort => 'ח';

  @override
  String get carbsShort => 'פח';

  @override
  String get fatShort => 'ש';

  @override
  String get timeSpent => 'זמן אימון';

  @override
  String get workoutCount => 'מספר אימונים';

  @override
  String get weekStart => 'תחילת שבוע';

  @override
  String get sunday => 'ראשון';

  @override
  String get monday => 'שני';

  @override
  String get weekendDays => 'ימי סופ״ש';

  @override
  String get fridaySaturday => 'שישי ושבת';

  @override
  String get saturdaySunday => 'שבת וראשון';

  @override
  String get defaultTimes => 'זמני ברירת מחדל';

  @override
  String get breakfast => 'ארוחת בוקר';

  @override
  String get lunch => 'ארוחת צהריים';

  @override
  String get dinner => 'ארוחת ערב';

  @override
  String get workoutTime => 'זמן אימון';

  @override
  String get notifications => 'התראות';

  @override
  String get sleepReminder => 'תזכורת שינה';

  @override
  String get workoutReminder => 'תזכורת אימון';

  @override
  String get enabled => 'מופעל';

  @override
  String get disabled => 'מבוטל';

  @override
  String get reminderTime => 'שעת תזכורת';

  @override
  String get meal => 'ארוחה';

  @override
  String get workout => 'אימון';

  @override
  String get sleepEntry => 'רישום שינה';

  @override
  String get january => 'ינואר';

  @override
  String get february => 'פברואר';

  @override
  String get march => 'מרץ';

  @override
  String get april => 'אפריל';

  @override
  String get may => 'מאי';

  @override
  String get june => 'יוני';

  @override
  String get july => 'יולי';

  @override
  String get august => 'אוגוסט';

  @override
  String get september => 'ספטמבר';

  @override
  String get october => 'אוקטובר';

  @override
  String get november => 'נובמבר';

  @override
  String get december => 'דצמבר';

  @override
  String get mondayShort => 'ב\'';

  @override
  String get tuesdayShort => 'ג\'';

  @override
  String get wednesdayShort => 'ד\'';

  @override
  String get thursdayShort => 'ה\'';

  @override
  String get fridayShort => 'ו\'';

  @override
  String get saturdayShort => 'ש\'';

  @override
  String get sundayShort => 'א\'';

  @override
  String get nutritionGoals => 'יעדי תזונה';

  @override
  String get calorieGoal => 'יעד קלוריות';

  @override
  String get proteinGoal => 'יעד חלבון';

  @override
  String get carbsGoal => 'יעד פחמימות';

  @override
  String get fatGoal => 'יעד שומן';

  @override
  String goalValidationError(Object max, Object min) {
    return 'אנא הכנס ערך בין $min ל-$max';
  }

  @override
  String get dashboardTab => 'דשבורד';

  @override
  String get mealsTab => 'ארוחות';

  @override
  String get workoutsTab => 'אימונים';

  @override
  String get sleepTab => 'שינה';

  @override
  String get settingsTab => 'הגדרות';

  @override
  String get monthView => 'תצוגת חודש';

  @override
  String get weekView => 'תצוגת שבוע';

  @override
  String get dayView => 'תצוגת יום';

  @override
  String get showPlanned => 'הצג מתוכננים';

  @override
  String get showCompleted => 'הצג הושלמו';

  @override
  String get addEvent => 'הוסף אירוע';

  @override
  String get editEvent => 'ערוך אירוע';

  @override
  String get markComplete => 'סמן כהושלם';

  @override
  String get eventSchedulingDialog => 'דיאלוג תזמון אירועים יוטמע בהמשך.';

  @override
  String get eventEditingDialog => 'דיאלוג עריכת אירועים יוטמע בהמשך.';

  @override
  String get refreshTooltip => 'רענן';

  @override
  String get calendarTooltip => 'לוח שנה';

  @override
  String get backToDashboardTooltip => 'חזור לדשבורד';

  @override
  String get addEventTooltip => 'הוסף אירוע';

  @override
  String get foodCatalogTooltip => 'קטלוג מזון';

  @override
  String get mealTemplates => 'תבניות ארוחות';

  @override
  String get createMealTemplate => 'צור תבנית ארוחה';

  @override
  String get editMealTemplate => 'ערוך תבנית ארוחה';

  @override
  String get noMealTemplates => 'אין תבניות ארוחות עדיין';

  @override
  String get createMealTemplateToReuse =>
      'צור תבניות ארוחות לשימוש חוזר מהיר בארוחות האהובות עליך';

  @override
  String get createFirstMealTemplate => 'צור תבנית ראשונה';

  @override
  String get templateName => 'שם התבנית';

  @override
  String get descriptionOptional => 'תיאור (אופציונלי)';

  @override
  String get foodItems => 'פריטי מזון';

  @override
  String get addFoodsToTemplate => 'הוסף מזון לתבנית';

  @override
  String get selectFoodsFromYourLibrary =>
      'בחר מזון מהספרייה שלך להכללה בתבנית זו';

  @override
  String get pleaseEnterTemplateName => 'אנא הכנס שם תבנית';

  @override
  String get pleaseAddAtLeastOneFood => 'נא להוסיף לפחות פריט מזון אחד';

  @override
  String get mealTemplateSaved => 'תבנית הארוחה נשמרה';

  @override
  String get mealCreatedFromTemplate => 'ארוחה נוצרה מתבנית';

  @override
  String get useNow => 'השתמש עכשיו';

  @override
  String get logNewMeal => 'רשום ארוחה חדשה';

  @override
  String get createMealFromScratch => 'צור ארוחה חדשה מאפס';

  @override
  String get useTemplate => 'השתמש בתבנית';

  @override
  String get chooseSavedMealTemplate => 'בחר מתבניות הארוחות השמורות';

  @override
  String get noFoodsAvailable => 'אין מזון זמין. צור קודם מזון.';

  @override
  String get selectFood => 'בחר מזון';

  @override
  String get pleaseEnterValidAmount => 'נא להזין כמות תקינה';

  @override
  String get addFoodTooltip => 'הוסף מזון';

  @override
  String get addSleepEntryTooltip => 'הוסף רישום שינה';

  @override
  String get finishWorkoutTooltip => 'סיים אימון';

  @override
  String get addExerciseTooltip => 'הוסף תרגיל';

  @override
  String get brandOptional => 'מותג (אופציונלי)';

  @override
  String get unit => 'יחידה';

  @override
  String get caloriesLabel => 'קלוריות';

  @override
  String get proteinGrams => 'חלבון (ג)';

  @override
  String get carbsGrams => 'פחמימות (ג)';

  @override
  String get fatGrams => 'שומן (ג)';

  @override
  String get bedtime => 'שעת שינה';

  @override
  String get wakeTimeOptional => 'שעת השכמה (אופציונלי)';

  @override
  String get notesOptional => 'הערות (אופציונלי)';

  @override
  String get mealTimeOptional => 'שעה (אופציונלי)';

  @override
  String get reps => 'חזרות';

  @override
  String get exerciseName => 'שם התרגיל';

  @override
  String get primaryMuscleOptional => 'שריר ראשי (אופציונלי)';

  @override
  String get mealName => 'שם הארוחה';

  @override
  String get searchFoods => 'חפש מזון';

  @override
  String get amount => 'כמות';

  @override
  String get defaultSets => 'סטים ברירת מחדל';

  @override
  String get defaultRepsOptional => 'חזרות ברירת מחדל (אופציונלי)';

  @override
  String get defaultRestOptional => 'מנוחה בין סטים (שניות)';

  @override
  String get defaultWeightOptional => 'משקל ברירת מחדל (אופציונלי)';

  @override
  String get sleepStartTime => 'שעת תחילת שינה';

  @override
  String get deleteFood => 'מחק מזון';

  @override
  String get finishWorkout => 'סיים אימון';

  @override
  String get deleteExercise => 'מחק תרגיל';

  @override
  String get sleepComplete => 'השינה הושלמה!';

  @override
  String deleteFoodConfirmation(Object name) {
    return 'האם אתה בטוח שברצונך למחוק את \"$name\"?';
  }

  @override
  String get finishWorkoutConfirmation =>
      'האם אתה בטוח שברצונך לסיים את האימון?';

  @override
  String deleteExerciseConfirmation(Object name) {
    return 'האם אתה בטוח שברצונך למחוק את \"$name\"?';
  }

  @override
  String get kilogramsKg => 'קילוגרמים (ק״ג)';

  @override
  String get poundsLb => 'פאונד (lb)';

  @override
  String get bodyweight => 'משקל גוף';

  @override
  String get pleaseEnterMealName => 'אנא הכנס שם ארוחה';

  @override
  String get pleaseAddExercise => 'אנא הוסף לפחות תרגיל אחד';

  @override
  String get pleaseEnterBedtime => 'אנא הכנס שעת שינה';

  @override
  String get finish => 'סיים';

  @override
  String get ok => 'אישור';

  @override
  String get foodCatalog => 'קטלוג מזון';

  @override
  String get exerciseLibrary => 'ספריית תרגילים';

  @override
  String get yourFoods => 'המזון שלך';

  @override
  String get starterList => 'רשימת התחלה';

  @override
  String get editFood => 'ערוך מזון';

  @override
  String get createWorkoutTemplate => 'צור תבנית אימון';

  @override
  String get exercises => 'תרגילים';

  @override
  String get addExercise => 'הוסף תרגיל';

  @override
  String get sets => 'סטים';

  @override
  String get weight => 'משקל';

  @override
  String get sleepTracking => 'מעקב שינה';

  @override
  String get wakeTime => 'שעת השכמה';

  @override
  String get quality => 'איכות';

  @override
  String get yesterday => 'אתמול';

  @override
  String get thisWeek => 'השבוע';

  @override
  String get lastWeek => 'השבוע שעבר';

  @override
  String get good => 'טוב';

  @override
  String get average => 'בינוני';

  @override
  String get poor => 'גרוע';

  @override
  String get kg => 'ק\"ג';

  @override
  String get lbs => 'פאונד';

  @override
  String get startTime => 'שעת התחלה';

  @override
  String get endTime => 'שעת סיום';

  @override
  String get notes => 'הערות';

  @override
  String get dailyTotals => 'סה״כ יומי';

  @override
  String get fuelUp => 'לאכול!';

  @override
  String get trackYourNutritionFor => 'עקוב אחר התזונה שלך ל־';

  @override
  String get logFirstMeal => 'רישום ארוחה ראשונה';

  @override
  String get designYourWorkouts => 'עצב את האימונים שלך';

  @override
  String get createFirstTemplate => 'צור תבנית ראשונה';

  @override
  String get yourFitnessJourneyAwaits => 'מסע הכושר שלך ממתין';

  @override
  String get completeWorkoutsWillAppear => 'האימונים שהושלמו יופיעו כאן';

  @override
  String get startQuickWorkout => 'התחל אימון מהיר';

  @override
  String get sweetDreamsAwait => 'חלומות נעימים';

  @override
  String get trackSleepForInsights =>
      'עקוב אחר השינה שלך לקבלת תובנות טובות יותר';

  @override
  String get startSleepTimer => 'התחל טיימר שינה';

  @override
  String get calendarTitle => 'לוח שנה';

  @override
  String get addMealsWorkoutsSleep => 'הוסף ארוחות, אימונים או שינה ליום זה';

  @override
  String get getMovingQuestion => 'בואו נזוז?';

  @override
  String get noDataAvailable => 'אין נתונים';

  @override
  String get viewAll => 'הצג הכל';

  @override
  String get viewCalendar => 'הצג יומן';

  @override
  String get yes => 'כן';

  @override
  String get no => 'לא';

  @override
  String get confirm => 'אשר';

  @override
  String get close => 'סגור';

  @override
  String get next => 'הבא';

  @override
  String get previous => 'הקודם';

  @override
  String get skip => 'דלג';

  @override
  String get retry => 'נסה שוב';

  @override
  String get deleteConfirmation => 'אישור מחיקה';

  @override
  String get areYouSure => 'האם אתה בטוח?';

  @override
  String get thisActionCannotBeUndone => 'פעולה זו לא ניתנת לביטול';

  @override
  String get deleteItem => 'מחק פריט';

  @override
  String get deleteWorkout => 'מחק אימון';

  @override
  String get deleteMeal => 'מחק ארוחה';

  @override
  String get deleteSleep => 'מחק רישום שינה';

  @override
  String get chooseTheme => 'בחר ערכת נושא';

  @override
  String get chooseLanguage => 'בחר שפה';

  @override
  String get cleanAndBright => 'ממשק נקי ובהיר';

  @override
  String get easyOnEyes => 'קל לעיניים באור חלש';

  @override
  String get luxuryGold => 'הדגשות זהב יוקרתיות על רקע כהה';

  @override
  String get leftToRight => 'טקסט משמאל לימין';

  @override
  String get rightToLeft => 'טקסט מימין לשמאל';

  @override
  String get pounds => 'פאונד (lbs)';

  @override
  String get addItem => 'הוסף פריט';

  @override
  String get removeItem => 'הסר פריט';

  @override
  String get quantity => 'כמות';

  @override
  String get servingSize => 'גודל מנה';

  @override
  String get totalCalories => 'סה״כ קלוריות';

  @override
  String get macronutrients => 'מקרו-נוטריינטים';

  @override
  String get workoutName => 'שם האימון';

  @override
  String get addSet => 'הוסף סט';

  @override
  String get removeSet => 'הסר סט';

  @override
  String get restTime => 'זמן מנוחה';

  @override
  String get totalTime => 'זמן כולל';

  @override
  String get completed => 'הושלם';

  @override
  String get notStarted => 'לא התחיל';

  @override
  String get sleepDuration => 'משך השינה';

  @override
  String get sleepQuality => 'איכות השינה';

  @override
  String get excellent => 'מעולה';

  @override
  String get veryGood => 'טוב מאוד';

  @override
  String get fair => 'בינוני';

  @override
  String get startTimer => 'התחל טיימר';

  @override
  String get stopTimer => 'עצור טיימר';

  @override
  String get pauseTimer => 'השהה טיימר';

  @override
  String get resumeTimer => 'המשך טיימר';

  @override
  String get selectDate => 'בחר תאריך';

  @override
  String get selectTime => 'בחר שעה';

  @override
  String get month => 'חודש';

  @override
  String get year => 'שנה';

  @override
  String get viewMode => 'מצב תצוגה';

  @override
  String get agenda => 'סדר יום';

  @override
  String get noEventsPlanned => 'אין אירועים מתוכננים';

  @override
  String get noEventsForThisDay => 'אין אירועים ליום זה';

  @override
  String get eventDetails => 'פרטי האירוע';

  @override
  String get eventType => 'סוג אירוע';

  @override
  String get loading => 'טוען...';

  @override
  String get error => 'שגיאה';

  @override
  String get success => 'הצלחה';

  @override
  String get warning => 'אזהרה';

  @override
  String get info => 'מידע';

  @override
  String get tryAgain => 'נסה שוב';

  @override
  String get somethingWentWrong => 'משהו השתבש';

  @override
  String get noInternetConnection => 'אין חיבור לאינטרנט';

  @override
  String get search => 'חיפוש';

  @override
  String get filter => 'סינון';

  @override
  String get sort => 'מיון';

  @override
  String get ascending => 'עולה';

  @override
  String get descending => 'יורד';

  @override
  String get clear => 'נקה';

  @override
  String get reset => 'איפוס';

  @override
  String get apply => 'החל';

  @override
  String get profile => 'פרופיל';

  @override
  String get privacy => 'פרטיות';

  @override
  String get help => 'עזרה';

  @override
  String get feedback => 'משוב';

  @override
  String get version => 'גרסה';

  @override
  String get backup => 'גיבוי';

  @override
  String get restore => 'שחזור';

  @override
  String get sync => 'סנכרון';

  @override
  String get required => 'נדרש';

  @override
  String get optional => 'אופציונלי';

  @override
  String get invalid => 'לא תקין';

  @override
  String get tooShort => 'קצר מדי';

  @override
  String get tooLong => 'ארוך מדי';

  @override
  String get enterValue => 'הזן ערך';

  @override
  String get selectOption => 'בחר אפשרות';

  @override
  String get seconds => 'שניות';

  @override
  String get days => 'ימים';

  @override
  String get weeks => 'שבועות';

  @override
  String get months => 'חודשים';

  @override
  String get update => 'עדכן';

  @override
  String get add => 'הוסף';

  @override
  String get noStarterFoodsAvailable => 'אין מזון התחלתי זמין';

  @override
  String get buildYourFoodLibrary => 'בנה את ספריית המזון שלך';

  @override
  String get starterFoodsWillAppear => 'מזון התחלתי יופיע כאן לאחר הטעינה';

  @override
  String get createCustomFoods => 'צור מזון מותאם אישית לרישום ארוחות מהיר';

  @override
  String get addFirstFood => 'הוסף מזון ראשון';

  @override
  String nutritionPer(Object unit) {
    return 'תזונה לכל $unit:';
  }

  @override
  String get unitDefault => 'יחידה';

  @override
  String get workoutSession => 'מושב אימון';

  @override
  String get addExercisesToGetStarted => 'הוסף תרגילים כדי להתחיל';

  @override
  String get completeSet => 'השלם סט';

  @override
  String get restTimer => 'טיימר מנוחה';

  @override
  String get pause => 'השהה';

  @override
  String get buildYourExerciseLibrary => 'בנה את ספריית התרגילים שלך';

  @override
  String get addExercisesToCreateWorkouts =>
      'הוסף תרגילים כדי ליצור אימונים מותאמים אישית';

  @override
  String get addFirstExercise => 'הוסף תרגיל ראשון';

  @override
  String get missed => 'הוחמץ';

  @override
  String get complete => 'השלם';

  @override
  String get enableNotifications => 'הפעל התראות';

  @override
  String get mealsNotificationDesc => 'קבל התראות לארוחות מתוזמנות';

  @override
  String get workoutsNotificationDesc => 'קבל התראות לאימונים מתוזמנים';

  @override
  String get sleepNotificationDesc => 'קבל התראות לשעת שינה ומעקב שינה';

  @override
  String get reminderTiming => 'זמן תזכורת';

  @override
  String get mealReminders => 'תזכורות לארוחות';

  @override
  String get workoutReminders => 'תזכורות לאימונים';

  @override
  String get sleepReminders => 'תזכורות לשינה';

  @override
  String get atTime => 'בזמן המתוזמן';

  @override
  String get fiveMinBefore => '5 דקות לפני';

  @override
  String get tenMinBefore => '10 דקות לפני';

  @override
  String get fifteenMinBefore => '15 דקות לפני';

  @override
  String get thirtyMinBefore => '30 דקות לפני';

  @override
  String xMinBefore(int minutes) {
    return '$minutes דקות לפני';
  }

  @override
  String get sleepSettings => 'הגדרות שינה';

  @override
  String get sleepGoal => 'יעד שינה';

  @override
  String get sleepLogReminder => 'תזכורת לרישום שינה';

  @override
  String sleepLogReminderDesc(String time) {
    return 'הזכר לי ב-$time אם לא רשמתי שינה';
  }

  @override
  String get quietHours => 'שעות שקט';

  @override
  String get quietHoursDesc => 'אל תשלח התראות בשעות אלו';

  @override
  String get sound => 'צליל';

  @override
  String get soundDesc => 'השמע צליל להתראות';

  @override
  String get vibration => 'רטט';

  @override
  String get vibrationDesc => 'הפעל רטט להתראות';

  @override
  String get scheduleEvent => 'תזמון אירוע';

  @override
  String get selectMealTemplate => 'תבנית ארוחה (אופציונלי)';

  @override
  String get selectWorkoutTemplate => 'תבנית אימון (אופציונלי)';

  @override
  String get noWorkoutTemplates => 'אין תבניות אימונים עדיין';

  @override
  String get selectTemplate => 'בחר תבנית';

  @override
  String get title => 'כותרת';

  @override
  String get titleRequired => 'נדרשת כותרת';

  @override
  String get description => 'תיאור';

  @override
  String get date => 'תאריך';

  @override
  String get repeat => 'חזרה';

  @override
  String get schedule => 'תזמן';

  @override
  String get noRepeat => 'ללא חזרה';

  @override
  String get daily => 'יומי';

  @override
  String get weekly => 'שבועי';

  @override
  String get monthly => 'חודשי';

  @override
  String get custom => 'מותאם אישית';

  @override
  String get selectDays => 'בחר ימים';

  @override
  String get every => 'כל';

  @override
  String get hasEndDate => 'תאריך סיום';

  @override
  String get endDate => 'תאריך סיום';

  @override
  String mealReminderNotification(String meal) {
    return 'זמן ל$meal!';
  }

  @override
  String mealReminderBodyNotification(String meal) {
    return 'הארוחה המתוזמנת שלך: $meal';
  }

  @override
  String get workoutReminderNotification => 'זמן לאמן!';

  @override
  String workoutReminderBodyNotification(String workout) {
    return 'מוכן ל$workout?';
  }

  @override
  String get sleepReminderNotification => 'זמן לישון';

  @override
  String get sleepReminderBodyNotification => 'התכונן לשינה טובה';

  @override
  String get onboardingWelcome => 'ברוך הבא!';

  @override
  String get onboardingChooseLanguage => 'בחר את השפה שלך להתחלה';

  @override
  String get onboardingContinue => 'המשך';

  @override
  String get onboardingSex => 'מין';

  @override
  String get onboardingMale => 'זכר';

  @override
  String get onboardingFemale => 'נקבה';

  @override
  String get onboardingAge => 'גיל';

  @override
  String get onboardingYears => 'שנים';

  @override
  String get onboardingHeight => 'גובה';

  @override
  String get onboardingWeight => 'משקל';

  @override
  String get onboardingPreferredUnits => 'יחידות מועדפות';

  @override
  String get onboardingEnergy => 'אנרגיה';

  @override
  String get onboardingWeightUnit => 'משקל';

  @override
  String get onboardingGoal => 'מה המטרה שלך?';

  @override
  String get onboardingGoalFatLoss => 'ירידה במשקל';

  @override
  String get onboardingGoalMuscleBuild => 'עלייה במסת שריר';

  @override
  String get onboardingGoalMaintenance => 'שמירה';

  @override
  String get onboardingGoalMobilityRehab => 'ניידות ושיקום';

  @override
  String get onboardingActivityLevel => 'רמת פעילות';

  @override
  String get onboardingActivitySedentary => 'בישיבה';

  @override
  String get onboardingActivityLight => 'קלה';

  @override
  String get onboardingActivityModerate => 'בינונית';

  @override
  String get onboardingActivityActive => 'פעילה';

  @override
  String get onboardingActivityVeryActive => 'פעילה מאוד';

  @override
  String get onboardingTrainingDays => 'ימי אימון בשבוע';

  @override
  String get onboardingDays => 'ימים';

  @override
  String get onboardingEquipment => 'ציוד זמין';

  @override
  String get onboardingEquipmentNone => 'ללא ציוד';

  @override
  String get onboardingEquipmentDumbbells => 'משקולות יד';

  @override
  String get onboardingEquipmentBarbell => 'מוט ומתקן';

  @override
  String get onboardingEquipmentMachines => 'מכשירים';

  @override
  String get onboardingEquipmentBands => 'רצועות התנגדות';

  @override
  String get onboardingEquipmentKettlebells => 'קטלבלים';

  @override
  String get onboardingEquipmentCable => 'מכונת כבלים';

  @override
  String get onboardingEquipmentPullup => 'מוט מתח';

  @override
  String get onboardingDietType => 'סוג תזונה';

  @override
  String get onboardingDietOmnivore => 'אוכל הכל';

  @override
  String get onboardingDietCarnivore => 'אוכל בשר';

  @override
  String get onboardingDietHerbivore => 'צמחי';

  @override
  String get onboardingMealsPerDay => 'ארוחות ביום';

  @override
  String get onboardingMeals2 => '2 ארוחות';

  @override
  String get onboardingMeals3 => '3 ארוחות';

  @override
  String get onboardingMeals4 => '4 ארוחות';

  @override
  String get onboardingMealsIF => 'צום לסירוגין 16:8';

  @override
  String get onboardingExclusions => 'מזונות להוצאה';

  @override
  String get onboardingExclusionsNone => 'ללא';

  @override
  String get onboardingExclusionsDairy => 'חלב';

  @override
  String get onboardingExclusionsGluten => 'גלוטן';

  @override
  String get onboardingExclusionsNuts => 'אגוזים';

  @override
  String get onboardingExclusionsEggs => 'ביצים';

  @override
  String get onboardingExclusionsShellfish => 'פירות ים';

  @override
  String get onboardingExclusionsSoy => 'סויה';

  @override
  String get onboardingInjuries => 'פציעות קיימות?';

  @override
  String get onboardingInjuriesNone => 'ללא';

  @override
  String get onboardingInjuriesShoulder => 'כתף';

  @override
  String get onboardingInjuriesBack => 'גב';

  @override
  String get onboardingInjuriesKnee => 'ברך';

  @override
  String get onboardingInjuriesAnkle => 'קרסול';

  @override
  String get onboardingInjuriesElbow => 'מרפק';

  @override
  String get onboardingInjuriesHip => 'ירך';

  @override
  String get onboardingInjuriesNeck => 'צוואר';

  @override
  String get onboardingBuildScheduleTitle => 'בנה לי לוח זמנים מלא';

  @override
  String get onboardingBuildScheduleSubtitle =>
      'הוסף אירועי אימון, ארוחות ושינה חוזרים ליומן, על בסיס התשובות שלך';

  @override
  String get onboardingSummaryTitle => 'התוכנית המותאמת שלך';

  @override
  String get onboardingSummaryTarget => 'יעד יומי';

  @override
  String get onboardingComplete => 'השלם הגדרה';

  @override
  String get onboardingBack => 'חזור';

  @override
  String get onboardingGoalTitle => 'מה המטרה העיקרית שלך?';

  @override
  String get onboardingActivityTitle => 'מה רמת הפעילות שלך?';

  @override
  String get onboardingExperienceTitle => 'ניסיון באימוני כוח';

  @override
  String get onboardingExperienceSubtitle =>
      'כמה זמן את/ה מתאמן/ת — זה קובע את המשקלים ההתחלתיים.';

  @override
  String get onboardingExperienceBeginner => 'מתחיל/ה';

  @override
  String get onboardingExperienceIntermediate => 'שנה-שנתיים';

  @override
  String get onboardingExperienceAdvanced => 'כמה שנים';

  @override
  String get onboardingTrainingTitle => 'כמה ימי אימון בשבוע?';

  @override
  String get onboardingEquipmentTitle => 'איזה ציוד יש לך?';

  @override
  String get onboardingDietTitle => 'מה סוג התזונה שלך?';

  @override
  String get onboardingMealsTitle => 'כמה ארוחות ביום?';

  @override
  String get onboardingExclusionsTitle => 'מזונות להוצאה?';

  @override
  String get onboardingInjuriesTitle => 'פציעות שצריך לעבוד סביבן?';

  @override
  String get onboardingBMR => 'BMR';

  @override
  String get onboardingTDEE => 'TDEE';

  @override
  String get onboardingGoalLabel => 'מטרה';

  @override
  String get restTimerCompleteTitle => '!המנוחה הסתיימה';

  @override
  String restTimerCompleteBody(String exercise) {
    return 'אפשר להמשיך עם $exercise';
  }

  @override
  String get sleepGoalReachedTitle => '!יעד השינה הושג';

  @override
  String sleepGoalReachedBody(String hours) {
    return 'ישנת $hours שעות -- זה בדיוק היעד שלך.';
  }

  @override
  String sleepStreakLabel(int count) {
    return 'רצף של $count לילות';
  }

  @override
  String get deleteOldData => 'מחיקת נתונים ישנים';

  @override
  String get deleteOldDataDescription =>
      'פנה מקום על ידי הסרת ארוחות, אימונים ורישומי שינה ישנים';

  @override
  String olderThanNDays(int days) {
    return 'ישן מ-$days ימים';
  }

  @override
  String deleteOldDataConfirmation(int days) {
    return 'פעולה זו תמחק לצמיתות ארוחות, אימונים ורישומי שינה שנרשמו לפני יותר מ-$days ימים. לא ניתן לבטל פעולה זו.';
  }

  @override
  String deleteOldDataResult(int count) {
    return 'נמחקו $count רשומות ישנות';
  }

  @override
  String get previousMonth => 'חודש קודם';

  @override
  String get nextMonth => 'חודש הבא';

  @override
  String get muteSound => 'השתק צליל';

  @override
  String get appearance => 'מראה';

  @override
  String get customizeSectionColors => 'התאמת צבעי מקטעים';

  @override
  String get customizeThemeAndColors => 'התאמת ערכת נושא וצבעים';

  @override
  String get back => 'חזור';

  @override
  String get markAsCompleted => 'סמן כהושלם';

  @override
  String get resetToDefaults => 'איפוס לברירת מחדל';

  @override
  String get sectionColors => 'צבעי מקטעים';

  @override
  String get nutritionColors => 'צבעי תזונה';

  @override
  String get followTheme => 'לפי ערכת הנושא';

  @override
  String get followThemeDesc => 'השתמש בצבע ערכת הנושא לכל מדדי התזונה';

  @override
  String get templates => 'תבניות';

  @override
  String get recent => 'אחרונים';

  @override
  String get resetAllData => 'איפוס כל הנתונים';

  @override
  String get resetAllDataDone => 'כל הנתונים אופסו. מתחילים מחדש.';

  @override
  String get resetThemeColors => 'איפוס צבעי ערכת הנושא';

  @override
  String get resetSectionColors => 'איפוס צבעי המקטעים';

  @override
  String get resetNutritionColors => 'איפוס צבעי התזונה';

  @override
  String get resetAllColors => 'איפוס כל הצבעים';

  @override
  String get primaryButton => 'כפתור ראשי';

  @override
  String get fiveMin => '5 דק\'';

  @override
  String get nutritionMetricsThemeColorLabel =>
      'כל מדדי התזונה ישתמשו בצבע ערכת הנושא הזה:';

  @override
  String get completedSets => 'סטים שהושלמו';

  @override
  String get currentColorLabel => 'נוכחי';

  @override
  String get customizeSectionColorsLabel => 'התאמת צבעים לכל מקטע:';

  @override
  String get customizeIndividualColorsLabel => 'התאמת צבעים בנפרד:';

  @override
  String get dailyOverview => 'סקירה יומית';

  @override
  String get dailyTargets => 'יעדים יומיים';

  @override
  String get defaultRestTime => 'זמן מנוחה ברירת מחדל';

  @override
  String get workoutTimerHint =>
      'במהלך אימונים אפשר להשתיק את הטיימר בעזרת לחצן עוצמת הקול ולהוסיף זמן מנוחה לפי הצורך.';

  @override
  String get editSleepSession => 'עריכת מפגש שינה';

  @override
  String get eventsAndActivities => 'אירועים ופעילויות';

  @override
  String get exerciseComplete => 'התרגיל הושלם!';

  @override
  String get exerciseSettings => 'הגדרות תרגיל';

  @override
  String get onboardingSummarySubtitle => 'הנה מה שחישבנו עבורך';

  @override
  String get hexCode => 'קוד הקס';

  @override
  String get hue => 'גוון';

  @override
  String get metabolicInfo => 'נתונים מטבוליים';

  @override
  String get nextExercise => 'התרגיל הבא';

  @override
  String get noRecentMeals => 'אין ארוחות אחרונות';

  @override
  String get noRecentWorkouts => 'אין אימונים אחרונים';

  @override
  String get nutritionTotals => 'סיכום תזונה';

  @override
  String get pasteJsonExportLabel => 'הדביקו כאן את נתוני הייצוא בפורמט JSON:';

  @override
  String get timerSoundSubtitle => 'השמעת צליל בסיום טיימר המנוחה';

  @override
  String get preciseControls => 'בקרות מדויקות';

  @override
  String get presets => 'ערכות מוכנות';

  @override
  String get preview => 'תצוגה מקדימה';

  @override
  String get repsUppercase => 'חזרות';

  @override
  String get restTimerUppercase => 'טיימר מנוחה';

  @override
  String get rgbValues => 'ערכי RGB';

  @override
  String get readyForSleep => 'מוכנים לישון?';

  @override
  String get saturationAndBrightness => 'רוויה ובהירות';

  @override
  String get selectExercise => 'בחירת תרגיל';

  @override
  String get selectFoodItem => 'בחירת מזון';

  @override
  String get selectAllThatApply => 'בחרו את כל המתאים';

  @override
  String get sleepQualityOptional => 'איכות שינה (אופציונלי)';

  @override
  String get sleepingEllipsis => 'ישנים...';

  @override
  String get readyForSleepSubtitle =>
      'הקישו על הכפתור למטה כדי להתחיל לעקוב אחר השינה';

  @override
  String get resetDataWarningBody =>
      'פעולה זו תמחק את כל הארוחות, האימונים, רשומות השינה והמזונות/התרגילים המותאמים אישית.\n\nהגדרות ערכת הנושא יישמרו.\n\nלא ניתן לבטל פעולה זו!';

  @override
  String get resetColorsWarningBody =>
      'פעולה זו תאפס את כל הצבעים המותאמים אישית לברירת המחדל. לא ניתן לבטל אותה.';

  @override
  String get timeBetweenSets => 'זמן בין סטים';

  @override
  String get timerSound => 'צליל טיימר';

  @override
  String get timerVolume => 'עוצמת טיימר';

  @override
  String get onboardingInjuriesHint => 'נציע תרגילי שיקום מתאימים';

  @override
  String get onboardingGoalsTitle => 'מה המטרות שלך?';

  @override
  String get workoutComplete => 'האימון הושלם!';

  @override
  String get workoutSettingsTitle => 'הגדרות אימון';

  @override
  String get analyticsTitle => 'ניתוח נתונים';

  @override
  String get analyticsRangeWeek => 'ש';

  @override
  String get analyticsRangeMonth => 'ח';

  @override
  String get analyticsRangeSixMonths => '6ח';

  @override
  String get analyticsRangeYear => 'שנה';

  @override
  String get analyticsGoalsReached => 'יעדים שהושגו';

  @override
  String get analyticsInsights => 'תובנות';

  @override
  String get analyticsTrainingVolume => 'נפח אימון';

  @override
  String get analyticsStrength => 'כוח';

  @override
  String get analyticsBodyWeight => 'משקל גוף';

  @override
  String get analyticsBodyWeightTrend => 'מגמת משקל גוף';

  @override
  String get analyticsSetsByMuscle => 'סטים לפי שריר';

  @override
  String get analyticsWorkingWeight => 'משקל עבודה';

  @override
  String get analyticsGoalTraining => 'אימון';

  @override
  String get analyticsGoalTrainingShort => 'אימון';

  @override
  String get analyticsGoalCaloriesShort => 'קלוריות';

  @override
  String get analyticsGoalProteinShort => 'חלבון';

  @override
  String get analyticsGoalSleepShort => 'שינה';

  @override
  String get analyticsAvgKcal => 'קלוריות בממוצע';

  @override
  String get analyticsAvgProtein => 'חלבון בממוצע';

  @override
  String get analyticsDaysLogged => 'ימים שנרשמו';

  @override
  String get analyticsSessions => 'אימונים';

  @override
  String get analyticsPerWeek => 'לשבוע';

  @override
  String get analyticsTimeSpent => 'זמן';

  @override
  String get analyticsNights => 'לילות';

  @override
  String get analyticsBedtimeSwing => 'פיזור שעת שינה';

  @override
  String get analyticsLatest => 'אחרון';

  @override
  String get analyticsChange => 'שינוי';

  @override
  String get analyticsLogWeight => 'רישום משקל';

  @override
  String get analyticsOtherMuscle => 'אחר';

  @override
  String get analyticsBodyweightLabel => 'משקל גוף';

  @override
  String get analyticsStrengthLegend =>
      'קו: 1RM משוער · נקודות: הסט הכבד ביותר';

  @override
  String get analyticsStreakDay => 'רצף של יום אחד';

  @override
  String analyticsStreakDays(String days) {
    return 'רצף של $days ימים';
  }

  @override
  String analyticsBestStreak(String days) {
    return 'שיא $days';
  }

  @override
  String analyticsAvgValue(String value) {
    return '$value בממוצע';
  }

  @override
  String analyticsBestE1rm(String value) {
    return '$value שיא 1RM משוער';
  }

  @override
  String analyticsTotalVolume(String value) {
    return '$value ק״ג סה״כ';
  }

  @override
  String analyticsVolumeValue(String value) {
    return '$value ק״ג';
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
    return '$count אימונים';
  }

  @override
  String analyticsWeekOf(String date) {
    return 'שבוע של $date';
  }

  @override
  String get analyticsEmptyAll =>
      'עדיין לא נרשם דבר בטווח הזה.\nרישום ארוחה, אימון או לילת שינה ימלא את זה.';

  @override
  String get analyticsEmptyGoals =>
      'הגדירו יעד קלוריות או חלבון כדי להתחיל לנקד את הימים.';

  @override
  String get analyticsEmptyMeals => 'לא נרשמו ארוחות בטווח הזה.';

  @override
  String get analyticsEmptyWorkouts => 'לא הושלמו אימונים בטווח הזה.';

  @override
  String get analyticsEmptySleep => 'לא נרשמו רשומות שינה מושלמות בטווח הזה.';

  @override
  String get analyticsEmptyStrength => 'רשמו כמה סטים כדי לראות את ההתקדמות.';

  @override
  String get analyticsEmptyWeighIns =>
      'עדיין אין שקילות. אחת לשבוע מספיקה כדי לראות מגמה.';

  @override
  String get analyticsBodyweightOnlyExercise =>
      'תרגיל זה במשקל גוף בלבד — אין משקל להציג.';

  @override
  String analyticsLoadError(String error) {
    return 'לא ניתן לטעון את הנתונים.\n$error';
  }

  @override
  String get analyticsWeightSheetTitle => 'המשקל היום';

  @override
  String get analyticsWeightSheetSubtitle => 'מחליף רשומה קודמת מהיום.';

  @override
  String get analyticsWeightSheetError => 'הזינו משקל בין 20 ל-400 ק״ג';

  @override
  String analyticsPlateauNewBest(String weight) {
    return '$weight · שיא חדש';
  }

  @override
  String analyticsPlateauMovedUp(String weight) {
    return '$weight · עלה';
  }

  @override
  String analyticsPlateauStalled(String weight, String sessions, String days) {
    return '$weight · $sessions אימונים · $days ימים';
  }

  @override
  String insightPlateau(String exercise, String weight, String sessions) {
    return '$exercise נשאר על $weight במשך $sessions אימונים — נסו להוסיף 2.5 ק״ג או חזרה נוספת.';
  }

  @override
  String insightPersonalBest(String exercise, String value) {
    return 'שיא חדש ב$exercise: $value 1RM משוער.';
  }

  @override
  String insightProteinShortfall(String actual, String goal) {
    return 'החלבון הסתכם בממוצע על $actual מול יעד של $goal.';
  }

  @override
  String insightCalorieDriftHigh(String actual, String goal) {
    return 'הקלוריות עומדות על $actual ליום מול יעד של $goal.';
  }

  @override
  String insightCalorieDriftLow(String actual, String goal) {
    return 'הקלוריות נמוכות: $actual ליום מול יעד של $goal.';
  }

  @override
  String insightVolumeDrop(String percent) {
    return 'נפח האימון ירד ב-$percent מהממוצע האחרון.';
  }

  @override
  String insightSleepDebt(String nights, String hours) {
    return 'ב-$nights מ-7 הלילות האחרונים ישנתם פחות מ-$hours.';
  }

  @override
  String insightConsistencyWin(String days) {
    return '$days ימים ברצף עם כל היעדים.';
  }

  @override
  String insightNeglectedMuscle(String sets, String muscle) {
    return 'רק $sets סטים ל$muscle בטווח הזה.';
  }

  @override
  String a11yChartNoData(String name) {
    return 'תרשים $name. אין נתונים בטווח הזה.';
  }

  @override
  String a11yChartHeader(String name, String period) {
    return 'תרשים $name, לפי $period.';
  }

  @override
  String a11yChartCoverage(String observed, String total, String period) {
    return '$observed מתוך $total $period עם נתונים.';
  }

  @override
  String a11yChartAverage(String average, String min, String max) {
    return 'ממוצע $average, מ-$min עד $max.';
  }

  @override
  String a11yChartGoal(String goal) {
    return 'יעד $goal.';
  }

  @override
  String get a11yPeriodDay => 'יום';

  @override
  String get a11yPeriodWeek => 'שבוע';

  @override
  String get a11yPeriodMonth => 'חודש';

  @override
  String get a11yPeriodDays => 'ימים';

  @override
  String get a11yPeriodWeeks => 'שבועות';

  @override
  String get a11yPeriodMonths => 'חודשים';

  @override
  String get a11yTrendFlat => 'יציב לאורך הטווח.';

  @override
  String get a11yTrendRoughlyFlat => 'יציב בערך לאורך הטווח.';

  @override
  String a11yTrendRising(String amount) {
    return 'עולה בכ- $amount לאורך הטווח.';
  }

  @override
  String a11yTrendFalling(String amount) {
    return 'יורד בכ- $amount לאורך הטווח.';
  }

  @override
  String get a11yGoalChartNoData => 'תרשים יעדים שהושגו. אין נתונים בטווח הזה.';

  @override
  String get a11yGoalChart => 'תרשים יעדים שהושגו.';

  @override
  String a11yGoalAverage(String percent) {
    return 'בממוצע $percent מהיעדים היומיים.';
  }

  @override
  String get a11yGoalStreakDay => 'רצף נוכחי: יום אחד עם כל היעדים.';

  @override
  String a11yGoalStreakDays(String days) {
    return 'רצף נוכחי: $days ימים עם כל היעדים.';
  }

  @override
  String get editSleepEntry => 'עריכת רישום שינה';

  @override
  String get startSleepAction => 'התחלת שינה';

  @override
  String get wakeUpAction => 'השכמה';

  @override
  String currentTimeLabel(String time) {
    return 'השעה כעת: $time';
  }

  @override
  String startedAtLabel(String time) {
    return 'התחיל ב-$time';
  }

  @override
  String get lastNightLabel => 'הלילה האחרון';

  @override
  String get sleepAvgSevenNights => 'ממוצע 7 לילות';

  @override
  String get streakLabel => 'רצף';

  @override
  String get sleepHistory => 'היסטוריית שינה';

  @override
  String hoursShortValue(String hours) {
    return '$hours ש\'';
  }

  @override
  String youSleptForHours(String hours) {
    return 'ישנת $hours שעות';
  }

  @override
  String fromTimeToTime(String start, String end) {
    return 'מ-$start עד $end';
  }

  @override
  String get howDidYouSleep => 'איך ישנת?';

  @override
  String get howAreYouFeeling => 'איך אתה מרגיש?';

  @override
  String get quickAdd => 'הוספה מהירה';

  @override
  String get quickAddMealSubtitle => 'תן שם והוסף מאכלים בלי לצאת מהמסך';

  @override
  String exercisesCount(int count) {
    return '$count תרגילים';
  }

  @override
  String setsCompletedCount(int count) {
    return '$count סטים הושלמו';
  }

  @override
  String get workoutSettingsTooltip => 'הגדרות אימון';

  @override
  String get mealNameHint => 'לדוגמה: ארוחת בוקר, צהריים, ערב';

  @override
  String itemsCount(int count) {
    return '$count פריטים';
  }

  @override
  String get searchExercises => 'חיפוש תרגילים';

  @override
  String get noExercisesFound => 'לא נמצאו תרגילים תואמים';

  @override
  String get primaryMuscle => 'שריר עיקרי';

  @override
  String get equipmentLabel => 'ציוד';

  @override
  String get targetSets => 'מספר סטים';

  @override
  String get targetReps => 'חזרות בסט';

  @override
  String get restBetweenSets => 'מנוחה בין סטים';

  @override
  String restAutoLabel(String duration) {
    return 'אוטומטי ($duration)';
  }

  @override
  String get restAutoExplainer =>
      'מבוסס על מספר החזרות. פחות חזרות = משקל כבד יותר ומנוחה ארוכה יותר.';

  @override
  String get addToWorkout => 'הוספה לאימון';

  @override
  String get exerciseDetails => 'פרטי התרגיל';

  @override
  String get editPrescription => 'עריכת סטים ומנוחה';

  @override
  String get removeFromWorkout => 'הסרה מהאימון';

  @override
  String quickWorkoutNamed(String date) {
    return 'אימון מהיר $date';
  }

  @override
  String exerciseAddedToWorkout(String name) {
    return '$name נוסף';
  }

  @override
  String setsAndRestSummary(int sets, String rest) {
    return '$sets סטים · $rest מנוחה';
  }

  @override
  String get noExercisesYet => 'אין עדיין תרגילים';

  @override
  String get workoutExercises => 'תרגילי האימון';
}
