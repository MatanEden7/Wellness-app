import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/date_utils.dart';
import 'core/theme.dart';
import 'features/calendar/data/calendar_service.dart';
import 'routing/routes.dart';
import 'services/background_refresh_service.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/notification_action_handler.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

class WellnessApp extends ConsumerStatefulWidget {
  const WellnessApp({super.key});

  @override
  ConsumerState<WellnessApp> createState() => _WellnessAppState();
}

class _WellnessAppState extends ConsumerState<WellnessApp> with WidgetsBindingObserver {
  DateTime _lastKnownDay = AppDateUtils.startOfDay(DateTime.now());
  Timer? _midnightCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Deferred to after the first frame so the router's navigator exists and
    // the handler has a context it can actually push routes onto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wireNotificationHandling();
      // Re-syncs the OS queue with the stored events on every launch. Without
      // it the queue only ever changed when an event was edited, so it drifted
      // out of date after a reboot, a timezone change, or simply time passing
      // (the recurrence horizon is 30 days and was never re-anchored).
      ref.read(calendarStateProvider.notifier).rescheduleAllNotifications();
      // Safety net for pins broken while the app was closed. Deleting a
      // template from the meal/workout screens leaves calendar events pointing
      // at a row that no longer exists -- there is no foreign key between the
      // SharedPreferences-backed calendar and the database, so nothing
      // cascades. Repairing centrally on launch covers every door, including
      // ones added later, rather than each delete site remembering to.
      ref.read(calendarStateProvider.notifier).repinDanglingTemplates();
    });

    // BackgroundRefreshService.onAppResumed()/onDateChanged() were fully
    // implemented but never called from anywhere -- the comment at their old
    // call site literally said "simplified - in real app use
    // WidgetsBindingObserver". Without this, data logged elsewhere (or the
    // day rolling over past midnight while the app stays foregrounded) never
    // refreshed the dashboard until the user manually navigated away and back.
    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final today = AppDateUtils.startOfDay(DateTime.now());
      if (today.isAfter(_lastKnownDay)) {
        _lastKnownDay = today;
        ref.read(backgroundRefreshServiceProvider).onDateChanged();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(backgroundRefreshServiceProvider).onAppResumed();
    }
  }

  @override
  void dispose() {
    _midnightCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Connects tapped notifications and their action buttons to
  /// [NotificationActionHandler].
  ///
  /// Without this, `NotificationService.onNotificationTap` was never assigned,
  /// so every Approve / Snooze / Start Workout button rendered but did
  /// nothing.
  void _wireNotificationHandling() {
    final notificationService = ref.read(notificationServiceProvider);

    notificationService.onNotificationTap = (NotificationResponse response) {
      if (!mounted) return;
      // Resolved per invocation rather than captured once: the navigator
      // context at wire-up time is not the one that is current when a
      // notification arrives minutes or hours later.
      final navigatorContext =
          ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;

      NotificationActionHandler(ref, navigatorContext)
          .handleNotificationResponse(response);
    };

    _handleColdStartLaunch(notificationService);
  }

  /// Handles the case where tapping a notification is what launched the app.
  /// The plugin does not replay that through `onDidReceiveNotificationResponse`,
  /// so it has to be pulled explicitly.
  Future<void> _handleColdStartLaunch(NotificationService service) async {
    final launchDetails = await service.getLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (response == null || !mounted) return;

    final navigatorContext =
        ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;
    await NotificationActionHandler(ref, navigatorContext)
        .handleNotificationResponse(response);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);

    // Notification title/body text is baked in at schedule time, so a pending
    // reminder keeps whatever language it was scheduled in until it's rebuilt.
    ref.listen<AppLanguage>(currentLanguageProvider, (previous, next) {
      if (previous == next) return;
      ref.read(calendarStateProvider.notifier).rescheduleAllNotifications();
    });
    final prefs = ref.watch(preferencesServiceProvider);
    
    return MaterialApp.router(
      title: 'Wellness App',
      theme: AppTheme.byKind(
        currentTheme,
        customPrimary: currentTheme == AppThemeKind.custom ? prefs.customPrimaryColor : null,
        customBackground: currentTheme == AppThemeKind.custom ? prefs.customBackgroundColor : null,
        customSurface: currentTheme == AppThemeKind.custom ? prefs.customSurfaceColor : null,
      ).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      
      // Localization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLanguage.values.map((lang) => lang.locale),
      locale: currentLanguage.locale,
      
      // RTL support - automatically handles text direction based on locale
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          // Honour the user's Dynamic Type / font-size setting, but cap it.
          // iOS accessibility sizes go past 300%, which overflows the dense
          // rows this app uses (macro chips, calendar cells, stat tiles).
          // Clamping degrades gracefully instead of throwing RenderFlex
          // overflows, while still respecting smaller-than-default settings
          // and a meaningful amount of enlargement.
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: Directionality(
            textDirection:
                currentLanguage.isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
      },
    );
  }
}
