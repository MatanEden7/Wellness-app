// ignore_for_file: avoid_positional_boolean_parameters
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/bridge/generated/chrome.g.dart',
  swiftOut: 'ios/Runner/Bridge/ChromeMessages.g.swift',
  dartPackageName: 'wellness_app',
))

// ─── Data classes ────────────────────────────────────────────────────────────

class TabSpec {
  const TabSpec({
    required this.index,
    required this.iconName,  // SF Symbol name
    required this.label,
    required this.accessibilityLabel,
  });
  final int index;
  final String iconName;
  final String label;
  final String accessibilityLabel;
}

class ChromeAction {
  const ChromeAction({
    required this.id,
    required this.iconName,   // SF Symbol name
    required this.title,
    this.isDestructive = false,
  });
  final String id;
  final String iconName;
  final String title;
  final bool isDestructive;
}

class PageChromeSpec {
  const PageChromeSpec({
    required this.title,
    required this.largeTitle,
    required this.showBack,
    this.backLabel,
    this.actions = const [],
    this.toolbarActions = const [],
    this.languageCode = 'en',
    this.isRTL = false,
  });
  final String title;
  final bool largeTitle;
  final bool showBack;
  final String? backLabel;
  final List<ChromeAction?> actions;
  final List<ChromeAction?> toolbarActions;
  final String languageCode;
  final bool isRTL;
}

class ChromeInsets {
  const ChromeInsets({
    required this.top,
    required this.bottom,
  });
  final double top;
  final double bottom;
}

// ─── Action sheet / alert ────────────────────────────────────────────────────

class ActionSheetItem {
  const ActionSheetItem({
    required this.id,
    required this.title,
    this.isDestructive = false,
  });
  final String id;
  final String title;
  final bool isDestructive;
}

class ActionSheetSpec {
  const ActionSheetSpec({
    this.title,
    this.message,
    required this.items,
    this.cancelLabel = 'Cancel',
  });
  final String? title;
  final String? message;
  final List<ActionSheetItem?> items;
  final String cancelLabel;
}

class AlertSpec {
  const AlertSpec({
    required this.title,
    this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
  });
  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
}

class MenuSpec {
  const MenuSpec({required this.items});
  final List<ActionSheetItem?> items;
}

class AnchorRect {
  const AnchorRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  final double x;
  final double y;
  final double width;
  final double height;
}

class DatePickerSpec {
  const DatePickerSpec({
    required this.mode,  // 'date' | 'time' | 'datetime'
    this.initialTimestamp,
    this.minTimestamp,
    this.maxTimestamp,
  });
  final String mode;
  final int? initialTimestamp;   // milliseconds since epoch
  final int? minTimestamp;
  final int? maxTimestamp;
}

class CapabilitiesSpec {
  const CapabilitiesSpec({
    required this.osVersion,
    required this.glassAvailable,
    required this.reduceTransparency,
    required this.reduceMotion,
    required this.dynamicTypeScale,
    required this.darkMode,
  });
  final String osVersion;
  final bool glassAvailable;
  final bool reduceTransparency;
  final bool reduceMotion;
  final double dynamicTypeScale;
  final bool darkMode;
}

// ─── Host APIs (Dart → Swift) ────────────────────────────────────────────────

@HostApi()
abstract class ChromeHostApi {
  void configureTabs(List<TabSpec> tabs);
  void setSelectedTab(int index);
  void setPageChrome(PageChromeSpec spec);
  void setChromeVisible(bool navBar, bool tabBar);
}

@HostApi()
abstract class PresentationHostApi {
  @async
  String? presentActionSheet(ActionSheetSpec spec);

  @async
  bool presentAlert(AlertSpec spec);

  @async
  String? presentMenu(MenuSpec spec, AnchorRect anchor);

  @async
  int? presentDatePicker(DatePickerSpec spec);  // returns timestamp ms

  @async
  void presentShare(List<String> paths, AnchorRect anchor);

  void haptic(String kind);  // 'light' | 'medium' | 'heavy' | 'selection' | 'success' | 'warning' | 'error'
}

@HostApi()
abstract class CapabilitiesApi {
  CapabilitiesSpec read();
}

// ─── Flutter API (Swift → Dart) ─────────────────────────────────────────────

@FlutterApi()
abstract class ChromeFlutterApi {
  void onTabSelected(int index);
  void onChromeAction(String actionId);
  void onBackPressed();
  void onInsetsChanged(ChromeInsets insets);
}
