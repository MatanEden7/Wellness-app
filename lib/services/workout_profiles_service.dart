enum WorkoutProfile {
  seniors,
  advanced,
  women,
  shoulderTherapy,
  backTherapy,
  kneeTherapy,
}

class WorkoutProfilesService {
  // Senior/Elderly Program - Focus on mobility, balance, and functional strength
  List<ExerciseData> getSeniorExercises(bool isHebrew) {
    return [
      ExerciseData(
        name: isHebrew ? 'הליכה במקום' : 'March in Place',
        primaryMuscle: isHebrew ? 'קרדיו' : 'Cardio',
        notes:
            isHebrew ? 'חימום עדין, 2-3 דקות' : 'Gentle warm-up, 2-3 minutes',
      ),
      ExerciseData(
        name: isHebrew ? 'עמידה וישיבה מכיסא' : 'Chair Sit-to-Stand',
        primaryMuscle: isHebrew ? 'רגליים, ישבן' : 'Legs, Glutes',
        notes: isHebrew
            ? 'שימוש בכיסא יציב לתמיכה'
            : 'Use stable chair for support',
      ),
      ExerciseData(
        name: isHebrew ? 'הרמת רגליים בצד' : 'Standing Leg Raise',
        primaryMuscle: isHebrew ? 'ירך, איזון' : 'Hip, Balance',
        notes: isHebrew ? 'אחיזה בקיר או כיסא' : 'Hold wall or chair',
      ),
      ExerciseData(
        name: isHebrew ? 'כפיפות קיר' : 'Wall Push-ups',
        primaryMuscle: isHebrew ? 'חזה, זרועות' : 'Chest, Arms',
        notes: isHebrew
            ? 'ידיים ברוחב כתפיים על הקיר'
            : 'Hands shoulder-width on wall',
      ),
      ExerciseData(
        name: isHebrew ? 'סיבובי כתפיים' : 'Shoulder Rolls',
        primaryMuscle: isHebrew ? 'כתפיים' : 'Shoulders',
        notes: isHebrew ? '10 קדימה, 10 אחורה' : '10 forward, 10 backward',
      ),
      ExerciseData(
        name: isHebrew ? 'מתיחת חתול-פרה' : 'Cat-Cow Stretch',
        primaryMuscle: isHebrew ? 'גב, ניידות' : 'Back, Mobility',
        notes:
            isHebrew ? 'על ארבע, תנועה איטית' : 'On all fours, slow movement',
      ),
    ];
  }

  List<WorkoutTemplateData> getSeniorTemplates(bool isHebrew) {
    return [
      WorkoutTemplateData(
        name:
            isHebrew ? 'כוח פונקציונלי לקשישים' : 'Senior Functional Strength',
        notes: isHebrew
            ? 'תרגילי כוח בטוחים לשמירה על עצמאות'
            : 'Safe strength exercises for maintaining independence',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 0,
              defaultSets: 2,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 1,
              defaultSets: 2,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 2,
              defaultSets: 2,
              defaultReps: 8,
              defaultWeight: null),
        ],
      ),
      WorkoutTemplateData(
        name: isHebrew ? 'איזון וניידות' : 'Balance & Mobility',
        notes: isHebrew
            ? 'שיפור איזון וטווחי תנועה'
            : 'Improve balance and range of motion',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 0,
              defaultSets: 1,
              defaultReps: 20,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 2,
              defaultSets: 2,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 5,
              defaultSets: 2,
              defaultReps: 8,
              defaultWeight: null),
        ],
      ),
    ];
  }

  // Advanced Program - Progressive overload, compound movements
  List<ExerciseData> getAdvancedExercises(bool isHebrew) {
    return [
      ExerciseData(
        name: isHebrew ? 'סקוואט משוקלל' : 'Barbell Squat',
        primaryMuscle: isHebrew ? 'רגליים, ישבן' : 'Legs, Glutes',
        notes: isHebrew
            ? 'עומק מלא, ברקים במקביל לרצפה'
            : 'Full depth, thighs parallel to floor',
      ),
      ExerciseData(
        name: isHebrew ? 'דדליפט' : 'Deadlift',
        primaryMuscle: isHebrew ? 'גב תחתון, רגליים' : 'Lower Back, Legs',
        notes:
            isHebrew ? 'גב ישר, משיכה מהרגליים' : 'Flat back, pull from legs',
      ),
      ExerciseData(
        name: isHebrew ? 'בנץ\' פרס' : 'Bench Press',
        primaryMuscle: isHebrew ? 'חזה, שלושי' : 'Chest, Triceps',
        notes: isHebrew
            ? 'תנועה מלאה, מרפקים 45 מעלות'
            : 'Full ROM, elbows 45 degrees',
      ),
      ExerciseData(
        name: isHebrew ? 'משיכות לסנטר' : 'Pull-ups',
        primaryMuscle: isHebrew ? 'גב עליון, דו-ראשי' : 'Upper Back, Biceps',
        notes: isHebrew
            ? 'אחיזה רחבה, סנטר מגיע לחזה'
            : 'Wide grip, chin over bar',
      ),
      ExerciseData(
        name: isHebrew ? 'פרס כתפיים עומד' : 'Overhead Press',
        primaryMuscle: isHebrew ? 'כתפיים, שלושי' : 'Shoulders, Triceps',
        notes: isHebrew
            ? 'פרס מעל הראש, ליבה מהודקת'
            : 'Press overhead, core tight',
      ),
      ExerciseData(
        name: isHebrew ? 'שורה משוקללת' : 'Barbell Row',
        primaryMuscle: isHebrew ? 'גב, דו-ראשי' : 'Back, Biceps',
        notes:
            isHebrew ? 'משיכה לבטן, גב במקביל' : 'Pull to belly, back parallel',
      ),
      ExerciseData(
        name: isHebrew ? 'לאנג\'ס משוקלל' : 'Bulgarian Split Squat',
        primaryMuscle: isHebrew ? 'רגליים, ישבן' : 'Legs, Glutes',
        notes: isHebrew ? 'רגל אחורית על ספסל' : 'Back foot elevated on bench',
      ),
    ];
  }

  List<WorkoutTemplateData> getAdvancedTemplates(bool isHebrew) {
    return [
      WorkoutTemplateData(
        name: isHebrew
            ? 'פוש - חזה, כתפיים, שלושי'
            : 'Push - Chest, Shoulders, Triceps',
        notes: isHebrew
            ? 'דחיפה משוקללת כבדה'
            : 'Heavy weighted pushing movements',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 2,
              defaultSets: 4,
              defaultReps: 6,
              defaultWeight: 60.0),
          ExerciseTemplateData(
              orderIndex: 4,
              defaultSets: 4,
              defaultReps: 6,
              defaultWeight: 40.0),
          ExerciseTemplateData(
              orderIndex: 0,
              defaultSets: 3,
              defaultReps: 8,
              defaultWeight: 80.0),
        ],
      ),
      WorkoutTemplateData(
        name: isHebrew ? 'פול - גב, דו-ראשי' : 'Pull - Back, Biceps',
        notes: isHebrew
            ? 'משיכות משוקללות כבדות'
            : 'Heavy weighted pulling movements',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 1,
              defaultSets: 4,
              defaultReps: 5,
              defaultWeight: 100.0),
          ExerciseTemplateData(
              orderIndex: 3,
              defaultSets: 4,
              defaultReps: 8,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 5,
              defaultSets: 3,
              defaultReps: 8,
              defaultWeight: 50.0),
        ],
      ),
      WorkoutTemplateData(
        name: isHebrew ? 'לגס - רגליים מלא' : 'Legs - Full Lower Body',
        notes: isHebrew
            ? 'אימון רגליים כבד ואינטנסיבי'
            : 'Heavy and intensive leg training',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 0,
              defaultSets: 5,
              defaultReps: 5,
              defaultWeight: 100.0),
          ExerciseTemplateData(
              orderIndex: 6,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: 20.0),
          ExerciseTemplateData(
              orderIndex: 1,
              defaultSets: 3,
              defaultReps: 6,
              defaultWeight: 80.0),
        ],
      ),
    ];
  }

  // Women's Program - Full body strength, core, flexibility
  List<ExerciseData> getWomenExercises(bool isHebrew) {
    return [
      ExerciseData(
        name: isHebrew ? 'סקוואט עם משקל גוף' : 'Bodyweight Squat',
        primaryMuscle: isHebrew ? 'רגליים, ישבן' : 'Legs, Glutes',
        notes: isHebrew ? 'ברכיים מתיישרות עם כף רגל' : 'Knees align with toes',
      ),
      ExerciseData(
        name: isHebrew ? 'לאנג\'ס' : 'Lunges',
        primaryMuscle: isHebrew ? 'רגליים, ישבן' : 'Legs, Glutes',
        notes: isHebrew
            ? 'צעד קדימה, ברך אחורית כמעט לרצפה'
            : 'Step forward, back knee nearly to floor',
      ),
      ExerciseData(
        name: isHebrew ? 'גשר ישבן' : 'Glute Bridge',
        primaryMuscle: isHebrew ? 'ישבן, גב תחתון' : 'Glutes, Lower Back',
        notes: isHebrew ? 'לחיצה בישבן בפסגה' : 'Squeeze glutes at top',
      ),
      ExerciseData(
        name: isHebrew ? 'פוש-אפ (ברכיים או מלא)' : 'Push-up (Knees or Full)',
        primaryMuscle: isHebrew ? 'חזה, זרועות' : 'Chest, Arms',
        notes:
            isHebrew ? 'גוף ישר, ליבה מהודקת' : 'Straight body, core engaged',
      ),
      ExerciseData(
        name: isHebrew ? 'פלאנק' : 'Plank',
        primaryMuscle: isHebrew ? 'ליבה' : 'Core',
        notes: isHebrew ? 'החזקת 30-60 שניות' : 'Hold for 30-60 seconds',
      ),
      ExerciseData(
        name: isHebrew ? 'פרפרים דמבל' : 'Dumbbell Fly',
        primaryMuscle: isHebrew ? 'חזה' : 'Chest',
        notes: isHebrew
            ? 'קשת רחבה, תנועה מבוקרת'
            : 'Wide arc, controlled movement',
      ),
      ExerciseData(
        name: isHebrew ? 'שורה דמבל' : 'Dumbbell Row',
        primaryMuscle: isHebrew ? 'גב, דו-ראשי' : 'Back, Biceps',
        notes: isHebrew
            ? 'משיכה למותניים, מרפק קרוב לגוף'
            : 'Pull to waist, elbow close',
      ),
      ExerciseData(
        name: isHebrew ? 'סקול קראשרס' : 'Bicycle Crunches',
        primaryMuscle: isHebrew ? 'בטן, אלכסוניים' : 'Abs, Obliques',
        notes: isHebrew ? 'מרפק לברך נגדית' : 'Elbow to opposite knee',
      ),
    ];
  }

  List<WorkoutTemplateData> getWomenTemplates(bool isHebrew) {
    return [
      WorkoutTemplateData(
        name: isHebrew ? 'גוף תחתון וישבן' : 'Lower Body & Glutes',
        notes: isHebrew ? 'חיטוב רגליים וישבן' : 'Tone legs and glutes',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 0,
              defaultSets: 3,
              defaultReps: 15,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 1,
              defaultSets: 3,
              defaultReps: 12,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 2,
              defaultSets: 3,
              defaultReps: 15,
              defaultWeight: null),
        ],
      ),
      WorkoutTemplateData(
        name: isHebrew ? 'גוף עליון וליבה' : 'Upper Body & Core',
        notes: isHebrew
            ? 'חיזוק חזה, גב וליבה'
            : 'Strengthen chest, back, and core',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 3,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 6,
              defaultSets: 3,
              defaultReps: 12,
              defaultWeight: 5.0),
          ExerciseTemplateData(
              orderIndex: 4,
              defaultSets: 3,
              defaultReps: 1,
              defaultWeight: null), // Hold time in "reps"
          ExerciseTemplateData(
              orderIndex: 7,
              defaultSets: 3,
              defaultReps: 20,
              defaultWeight: null),
        ],
      ),
      WorkoutTemplateData(
        name: isHebrew ? 'גוף מלא עם משקולות' : 'Full Body with Weights',
        notes: isHebrew
            ? 'כל הגוף עם דמבלים קלים'
            : 'Total body with light dumbbells',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 0,
              defaultSets: 3,
              defaultReps: 12,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 5,
              defaultSets: 3,
              defaultReps: 12,
              defaultWeight: 8.0),
          ExerciseTemplateData(
              orderIndex: 6,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: 8.0),
          ExerciseTemplateData(
              orderIndex: 2,
              defaultSets: 3,
              defaultReps: 15,
              defaultWeight: null),
        ],
      ),
    ];
  }

  // Shoulder Therapy - Rehabilitation exercises
  List<ExerciseData> getShoulderTherapyExercises(bool isHebrew) {
    return [
      ExerciseData(
        name: isHebrew ? 'תליה מכתף (פנדולום)' : 'Pendulum Swings',
        primaryMuscle: isHebrew ? 'כתף - ניידות' : 'Shoulder - Mobility',
        notes: isHebrew
            ? 'רגוע, תנועות קטנות מעגליות'
            : 'Relaxed, small circular motions',
      ),
      ExerciseData(
        name:
            isHebrew ? 'סיבוב חיצוני עם רצועה' : 'External Rotation with Band',
        primaryMuscle: isHebrew ? 'רוטטור כאף' : 'Rotator Cuff',
        notes:
            isHebrew ? 'מרפק צמוד לגוף, 90 מעלות' : 'Elbow at side, 90 degrees',
      ),
      ExerciseData(
        name: isHebrew ? 'סיבוב פנימי עם רצועה' : 'Internal Rotation with Band',
        primaryMuscle: isHebrew ? 'רוטטור כאף' : 'Rotator Cuff',
        notes: isHebrew
            ? 'מרפק צמוד, סיבוב פנימה'
            : 'Elbow at side, rotate inward',
      ),
      ExerciseData(
        name: isHebrew ? 'הרמת זרוע קדימה' : 'Front Arm Raise',
        primaryMuscle: isHebrew ? 'כתף קדמית' : 'Front Shoulder',
        notes:
            isHebrew ? 'ללא משקל או משקל קל מאוד' : 'No weight or very light',
      ),
      ExerciseData(
        name: isHebrew ? 'הרמת זרוע הצידה' : 'Lateral Arm Raise',
        primaryMuscle: isHebrew ? 'כתף צידית' : 'Side Shoulder',
        notes: isHebrew
            ? 'זרוע ישרה, עד גובה כתף'
            : 'Straight arm, up to shoulder height',
      ),
      ExerciseData(
        name: isHebrew ? 'מתיחת דלת (דורסיפלקשן)' : 'Doorway Stretch',
        primaryMuscle: isHebrew ? 'חזה, כתף קדמית' : 'Chest, Front Shoulder',
        notes: isHebrew ? 'החזקת 30 שניות' : 'Hold for 30 seconds',
      ),
    ];
  }

  List<WorkoutTemplateData> getShoulderTherapyTemplates(bool isHebrew) {
    return [
      WorkoutTemplateData(
        name: isHebrew ? 'שיקום כתף - שלב 1' : 'Shoulder Rehab - Phase 1',
        notes: isHebrew
            ? 'תרגילים עדינים לניידות כתף'
            : 'Gentle shoulder mobility exercises',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 0,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 1,
              defaultSets: 2,
              defaultReps: 15,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 5,
              defaultSets: 3,
              defaultReps: 1,
              defaultWeight: null),
        ],
      ),
      WorkoutTemplateData(
        name: isHebrew ? 'חיזוק רוטטור כאף' : 'Rotator Cuff Strengthening',
        notes: isHebrew
            ? 'חיזוק שרירי היציבות של הכתף'
            : 'Strengthen shoulder stabilizers',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 1,
              defaultSets: 3,
              defaultReps: 15,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 2,
              defaultSets: 3,
              defaultReps: 15,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 3,
              defaultSets: 2,
              defaultReps: 12,
              defaultWeight: 1.0),
          ExerciseTemplateData(
              orderIndex: 4,
              defaultSets: 2,
              defaultReps: 12,
              defaultWeight: 1.0),
        ],
      ),
    ];
  }

  // Back Therapy - Lower back pain relief
  List<ExerciseData> getBackTherapyExercises(bool isHebrew) {
    return [
      ExerciseData(
        name: isHebrew ? 'נטרול אגן (פלביק טילט)' : 'Pelvic Tilt',
        primaryMuscle: isHebrew ? 'גב תחתון, ליבה' : 'Lower Back, Core',
        notes: isHebrew
            ? 'שוכבים, לחיצת גב לרצפה'
            : 'Lying down, press back to floor',
      ),
      ExerciseData(
        name: isHebrew ? 'חתול-פרה' : 'Cat-Cow',
        primaryMuscle: isHebrew ? 'עמוד שדרה' : 'Spine',
        notes: isHebrew ? 'תנועה איטית וזורמת' : 'Slow flowing movement',
      ),
      ExerciseData(
        name: isHebrew ? 'ילד (צ\'יילד פוז)' : 'Child\'s Pose',
        primaryMuscle: isHebrew ? 'גב, מתיחה' : 'Back, Stretch',
        notes: isHebrew ? 'החזקת 30-60 שניות' : 'Hold for 30-60 seconds',
      ),
      ExerciseData(
        name: isHebrew ? 'ברד-דוג' : 'Bird Dog',
        primaryMuscle: isHebrew ? 'גב, יציבות ליבה' : 'Back, Core Stability',
        notes: isHebrew
            ? 'רגל וזרוע נגדית, איזון'
            : 'Opposite arm and leg, balance',
      ),
      ExerciseData(
        name: isHebrew ? 'גשר (ברידג\')' : 'Glute Bridge',
        primaryMuscle: isHebrew ? 'ישבן, גב תחתון' : 'Glutes, Lower Back',
        notes: isHebrew
            ? 'הרמה איטית, החזקה 2 שניות'
            : 'Slow lift, hold 2 seconds',
      ),
      ExerciseData(
        name: isHebrew ? 'פלאנק ברכיים' : 'Knee Plank',
        primaryMuscle: isHebrew ? 'ליבה' : 'Core',
        notes: isHebrew ? '20-30 שניות, גב ישר' : '20-30 seconds, flat back',
      ),
      ExerciseData(
        name: isHebrew ? 'מתיחת ברכיים לחזה' : 'Knee to Chest Stretch',
        primaryMuscle: isHebrew ? 'גב תחתון' : 'Lower Back',
        notes: isHebrew ? 'החזקת 30 שניות כל רגל' : 'Hold 30 seconds each leg',
      ),
    ];
  }

  List<WorkoutTemplateData> getBackTherapyTemplates(bool isHebrew) {
    return [
      WorkoutTemplateData(
        name: isHebrew ? 'הקלה על כאבי גב' : 'Back Pain Relief',
        notes: isHebrew
            ? 'תרגילים עדינים להקלה וניידות'
            : 'Gentle exercises for relief and mobility',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 0,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 1,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 2,
              defaultSets: 2,
              defaultReps: 1,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 6,
              defaultSets: 2,
              defaultReps: 1,
              defaultWeight: null),
        ],
      ),
      WorkoutTemplateData(
        name:
            isHebrew ? 'חיזוק ליבה לגב בריא' : 'Core Strength for Healthy Back',
        notes: isHebrew
            ? 'בניית כוח ליבה למניעת כאבים'
            : 'Build core strength to prevent pain',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 3,
              defaultSets: 3,
              defaultReps: 8,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 4,
              defaultSets: 3,
              defaultReps: 12,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 5,
              defaultSets: 3,
              defaultReps: 1,
              defaultWeight: null),
        ],
      ),
    ];
  }

  // Knee Therapy - Knee pain rehabilitation
  List<ExerciseData> getKneeTherapyExercises(bool isHebrew) {
    return [
      ExerciseData(
        name: isHebrew ? 'הרמת רגל ישרה' : 'Straight Leg Raise',
        primaryMuscle: isHebrew ? 'קוודריצפס' : 'Quadriceps',
        notes: isHebrew
            ? 'שוכבים, רגל ישרה מורמת'
            : 'Lying down, straight leg lift',
      ),
      ExerciseData(
        name: isHebrew ? 'כיפוף ברך בישיבה' : 'Seated Knee Extension',
        primaryMuscle: isHebrew ? 'קוודריצפס' : 'Quadriceps',
        notes: isHebrew ? 'יושבים, יישור רגל' : 'Sitting, straighten leg',
      ),
      ExerciseData(
        name: isHebrew ? 'כיפוף ברך עומד' : 'Standing Hamstring Curl',
        primaryMuscle: isHebrew ? 'האמסטרינג' : 'Hamstrings',
        notes: isHebrew
            ? 'אחיזה בכיסא, כיפוף לישבן'
            : 'Hold chair, bend toward glutes',
      ),
      ExerciseData(
        name: isHebrew ? 'מיני סקוואט רדוד' : 'Mini Squats',
        primaryMuscle: isHebrew ? 'רגליים' : 'Legs',
        notes: isHebrew
            ? 'כיפוף קל 45 מעלות בלבד'
            : 'Shallow bend, 45 degrees only',
      ),
      ExerciseData(
        name: isHebrew ? 'צעדים לצד' : 'Side Steps',
        primaryMuscle: isHebrew ? 'ירך, ייצוב ברך' : 'Hip, Knee Stability',
        notes: isHebrew ? 'צעדים איטיים הצידה' : 'Slow steps to the side',
      ),
      ExerciseData(
        name: isHebrew ? 'לחיצת כרית בין ברכיים' : 'Pillow Squeeze',
        primaryMuscle: isHebrew ? 'מוביר פנימי' : 'Inner Thigh',
        notes: isHebrew ? 'החזקת 5 שניות' : 'Hold for 5 seconds',
      ),
      ExerciseData(
        name: isHebrew ? 'מתיחת האמסטרינג' : 'Hamstring Stretch',
        primaryMuscle: isHebrew ? 'האמסטרינג' : 'Hamstrings',
        notes: isHebrew ? 'החזקת 30 שניות' : 'Hold for 30 seconds',
      ),
    ];
  }

  List<WorkoutTemplateData> getKneeTherapyTemplates(bool isHebrew) {
    return [
      WorkoutTemplateData(
        name: isHebrew ? 'שיקום ברך - בסיסי' : 'Knee Rehab - Basic',
        notes: isHebrew
            ? 'תרגילים עדינים לחיזוק ברך'
            : 'Gentle exercises to strengthen knee',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 0,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 1,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 5,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: null),
        ],
      ),
      WorkoutTemplateData(
        name: isHebrew ? 'חיזוק ויציבות ברך' : 'Knee Strength & Stability',
        notes: isHebrew
            ? 'בניית כוח לייצוב הברך'
            : 'Build strength to stabilize knee',
        exercises: [
          ExerciseTemplateData(
              orderIndex: 2,
              defaultSets: 3,
              defaultReps: 12,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 3,
              defaultSets: 3,
              defaultReps: 10,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 4,
              defaultSets: 3,
              defaultReps: 20,
              defaultWeight: null),
          ExerciseTemplateData(
              orderIndex: 6,
              defaultSets: 2,
              defaultReps: 1,
              defaultWeight: null),
        ],
      ),
    ];
  }
}

// Helper classes for data structure
class ExerciseData {
  final String name;
  final String? primaryMuscle;
  final String? notes;

  ExerciseData({
    required this.name,
    this.primaryMuscle,
    this.notes,
  });
}

class WorkoutTemplateData {
  final String name;
  final String? notes;
  final List<ExerciseTemplateData> exercises;

  WorkoutTemplateData({
    required this.name,
    this.notes,
    required this.exercises,
  });
}

class ExerciseTemplateData {
  final int orderIndex;
  final int defaultSets;
  final int defaultReps;
  final double? defaultWeight;

  ExerciseTemplateData({
    required this.orderIndex,
    required this.defaultSets,
    required this.defaultReps,
    this.defaultWeight,
  });
}
