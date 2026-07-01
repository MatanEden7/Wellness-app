import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/dashboard/ui/dashboard_page.dart';
import '../features/meals/ui/meals_page.dart';
import '../features/meals/ui/meal_editor_page.dart';
import '../features/meals/ui/food_catalog_page.dart';
import '../features/meals/ui/meal_templates_page.dart';
import '../features/meals/ui/meal_template_editor_page.dart';
import '../features/workouts/ui/workouts_page.dart';
import '../features/workouts/ui/exercise_library_page.dart';
import '../features/workouts/ui/template_editor_page.dart';
import '../features/workouts/ui/workout_session_page.dart';
import '../features/sleep/ui/sleep_page.dart';
import '../features/sleep/ui/sleep_timer_page.dart';
import '../features/calendar/ui/calendar_page.dart';
import '../features/settings/ui/settings_stub.dart';
import '../features/settings/ui/appearance_editor_page.dart';
import '../features/settings/ui/notification_settings_page.dart';
import '../features/settings/ui/workout_settings_page.dart';
import '../features/setup/ui/onboarding_page.dart';
import '../services/user_profile_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Get the profile service once
  final profileService = ref.read(userProfileServiceProvider);
  
  return GoRouter(
    initialLocation: '/',
    // Enable back swipe gesture on iOS/macOS
    observers: [
      if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)
        HeroController(),
    ],
    // Make router refresh when profile service changes
    refreshListenable: profileService,
    redirect: (context, state) {
      // Read isSetupCompleted fresh each time redirect runs
      final isSetupComplete = profileService.isSetupCompleted;
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      
      print('[ROUTER] Redirect check: isSetupComplete=$isSetupComplete, location=${state.matchedLocation}');
      
      // If setup is not complete and not already on onboarding, redirect
      if (!isSetupComplete && !isOnOnboarding) {
        print('[ROUTER] Redirecting to onboarding');
        return '/onboarding';
      }
      
      // If setup is complete and on onboarding, redirect to dashboard
      if (isSetupComplete && isOnOnboarding) {
        print('[ROUTER] Redirecting to dashboard');
        return '/';
      }
      
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _platformPage(const OnboardingPage()),
      ),
      GoRoute(
        path: '/',
        name: 'dashboard',
        pageBuilder: (context, state) => _platformPage(const DashboardPage()),
      ),
      GoRoute(
        path: '/meals',
        name: 'meals',
        pageBuilder: (context, state) => _platformPage(const MealsPage()),
        routes: [
          GoRoute(
            path: 'edit/:mealId',
            name: 'meal_editor_with_id',
            pageBuilder: (context, state) {
              final mealId = state.pathParameters['mealId']!;
              return _platformPage(MealEditorPage(mealId: mealId));
            },
          ),
          GoRoute(
            path: 'edit',
            name: 'meal_editor_new',
            pageBuilder: (context, state) => _platformPage(const MealEditorPage()),
          ),
          GoRoute(
            path: 'foods',
            name: 'food_catalog',
            pageBuilder: (context, state) => _platformPage(const FoodCatalogPage()),
          ),
          GoRoute(
            path: 'templates',
            name: 'meal_templates',
            pageBuilder: (context, state) => _platformPage(const MealTemplatesPage()),
            routes: [
              // IMPORTANT: Specific routes must come BEFORE parameterized routes
              GoRoute(
                path: 'new',
                name: 'meal_template_editor_new',
                pageBuilder: (context, state) => _platformPage(const MealTemplateEditorPage()),
              ),
              GoRoute(
                path: ':templateId',
                name: 'meal_template_editor_with_id',
                pageBuilder: (context, state) {
                  final templateId = state.pathParameters['templateId']!;
                  return _platformPage(MealTemplateEditorPage(templateId: templateId));
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/workouts',
        name: 'workouts',
        pageBuilder: (context, state) => _platformPage(const WorkoutsPage()),
        routes: [
          GoRoute(
            path: 'exercises',
            name: 'exercise_library',
            pageBuilder: (context, state) => _platformPage(const ExerciseLibraryPage()),
          ),
          GoRoute(
            path: 'templates/:templateId',
            name: 'template_editor_with_id',
            pageBuilder: (context, state) {
              final templateId = state.pathParameters['templateId']!;
              return _platformPage(TemplateEditorPage(templateId: templateId));
            },
          ),
          GoRoute(
            path: 'templates',
            name: 'template_editor_new',
            pageBuilder: (context, state) => _platformPage(const TemplateEditorPage()),
          ),
          GoRoute(
            path: 'session/:sessionId',
            name: 'workout_session',
            pageBuilder: (context, state) {
              final sessionId = state.pathParameters['sessionId']!;
              return _platformPage(WorkoutSessionPage(sessionId: sessionId));
            },
          ),
        ],
      ),
      GoRoute(
        path: '/sleep',
        name: 'sleep',
        pageBuilder: (context, state) => _platformPage(const SleepPage()),
        routes: [
          GoRoute(
            path: 'timer',
            name: 'sleep_timer',
            pageBuilder: (context, state) => _platformPage(const SleepTimerPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        pageBuilder: (context, state) => _platformPage(const CalendarPage()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _platformPage(const SettingsStub()),
        routes: [
          GoRoute(
            path: 'appearance',
            name: 'appearance_editor',
            pageBuilder: (context, state) => _platformPage(const AppearanceEditorPage()),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notification_settings',
            pageBuilder: (context, state) => _platformPage(const NotificationSettingsPage()),
          ),
          GoRoute(
            path: 'workouts',
            name: 'workout_settings',
            pageBuilder: (context, state) => _platformPage(const WorkoutSettingsPage()),
          ),
        ],
      ),
    ],
  );
});

// Route names for easy navigation
class Routes {
  static const onboarding = '/onboarding';
  static const dashboard = '/';
  static const meals = '/meals';
  static const mealEditor = '/meals/edit';
  static const foodCatalog = '/meals/foods';
  static const mealTemplates = '/meals/templates';
  static const mealTemplateEditor = '/meals/templates/new';
  static const workouts = '/workouts';
  static const exerciseLibrary = '/workouts/exercises';
  static const templateEditor = '/workouts/templates';
  static const workoutSession = '/workouts/session';
  static const sleep = '/sleep';
  static const sleepTimer = '/sleep/timer';
  static const calendar = '/calendar';
  static const settings = '/settings';
  static const appearanceEditor = '/settings/appearance';
  static const notificationSettings = '/settings/notifications';
  static const workoutSettings = '/settings/workouts';
}

// Navigation helpers
extension GoRouterExtension on GoRouter {
  void goToMealEditor([String? mealId]) {
    if (mealId != null) {
      go('/meals/edit/$mealId');
    } else {
      go('/meals/edit');
    }
  }

  void goToTemplateEditor([String? templateId]) {
    if (templateId != null) {
      go('/workouts/templates/$templateId');
    } else {
      go('/workouts/templates');
    }
  }

  void goToWorkoutSession(String sessionId) {
    go('/workouts/session/$sessionId');
  }
}

// Use CupertinoPage on iOS/macOS to enable edge-swipe back gesture, Material elsewhere
Page<dynamic> _platformPage(Widget child, {bool fullscreenDialog = false}) {
  if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
    return CupertinoPage<dynamic>(
      child: child,
      fullscreenDialog: fullscreenDialog,
    );
  }
  return MaterialPage<dynamic>(
    child: child,
    fullscreenDialog: fullscreenDialog,
  );
}
