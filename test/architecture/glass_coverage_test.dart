/// Enforces the layer split, which is the one rule the whole design rests on.
///
/// Apple's iOS 26 system has three layers and gives each a different material:
/// content is opaque, the functional layer that floats above it is Liquid
/// Glass, and the navigation bars are the system's own glass. "Applying Liquid
/// Glass directly to content" is on Apple's list of anti-patterns.
///
/// This app learned that the hard way: glass went onto every card, and the
/// screens read as washed out precisely because nothing was left for the glass
/// to float *over*. Two rules keep it from happening again.
@Tags(['ui'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files whose contents float above content, and may therefore paint glass.
///
/// Adding a file here is a design decision, not a formality: it asserts that
/// what the file draws sits on the functional layer.
const _functional = <String, String>{
  'lib/core/ios/glass.dart': 'the material itself',
  'lib/core/ios/app_scaffold.dart': 'nav bar, pinned bar, bottom bar',
  'lib/core/ios/controls.dart': 'search field, segmented control, filter bar',
  'lib/core/ios/date_strip.dart': 'the day picker floats over the list',
  'lib/core/tag_chips.dart': 'chips are controls',
  'lib/core/ios/liquid_glass_tab_bar.dart': 'the fallback tab bar',
  'lib/shell/platform_page.dart': 'the pinned header',
  'lib/core/widgets.dart': 'AppSheet — a modal sheet floats',
  'lib/features/settings/ui/advanced_color_picker.dart': 'a modal sheet',
  'lib/features/calendar/ui/event_scheduling_dialog.dart': 'a modal dialog',
  'lib/features/settings/ui/notification_settings_page.dart':
      'the sleep-goal slider sheet floats',
  'lib/features/meals/ui/meal_editor_page.dart': 'hosts a modal dialog',
  'lib/features/meals/ui/meal_template_editor_page.dart':
      'hosts a modal dialog',
  'lib/features/workouts/ui/template_editor_page.dart': 'hosts modal dialogs',
  'lib/features/sleep/ui/sleep_timer_page.dart': 'hosts a modal dialog',
  'lib/features/analytics/ui/sections/strength_section.dart': 'a modal sheet',
  'lib/features/analytics/ui/widgets/log_weight_sheet.dart': 'a modal sheet',
  'lib/features/calendar/ui/calendar_page.dart': 'the day-agenda sheet',
  'lib/features/workouts/ui/workouts_page.dart': 'hosts a modal sheet',
  'lib/features/dashboard/ui/dashboard_page.dart': 'hosts modal sheets',
};

/// Surfaces that must be painted literally — outside *both* materials, with why.
const _rawSurfaceAllowed = <String, String>{
  'lib/core/ios/liquid_glass_tab_bar.dart': 'paints the material itself',
  'lib/features/settings/ui/advanced_color_picker.dart':
      'swatches must render the literal colour',
  'lib/features/settings/ui/appearance_editor_page.dart':
      'colour previews must render the literal colour',
  'lib/features/settings/ui/theme_page.dart':
      'theme previews must render the literal colour',
  'lib/core/ios/swipe_row.dart': 'the swipe reveal sits under the row',
  'lib/core/widgets.dart': 'progress-bar track and fill',
  'lib/features/workouts/ui/workout_session_page.dart': 'rest-timer bar',
  'lib/features/analytics/ui/sections/goals_section.dart': 'legend dots',
  'lib/features/calendar/ui/calendar_page.dart': 'hairline dividers',
  'lib/features/calendar/ui/ios_month_calendar.dart': 'day circles and dots',
  'lib/shell/material/material_page_shell.dart': 'Material shell, by design',
  'lib/core/theme.dart': 'theme definitions, not widgets',
  'lib/core/design/surfaces.dart': 'the content material itself',
  // Not a surface: an overlay tint laid *over* one, replacing the ink ripple.
  // A ContentSurface here would paint a second card on top of the row.
  'lib/core/ios/pressable.dart': 'the press highlight, not a surface',
  // The banner is real UIKit on iOS (BannerPresenter.swift); this is only the
  // Android/widget-test stand-in, so it has no glass to inherit.
  'lib/core/ios/feedback.dart': 'Flutter fallback banner, off the iOS path',
};

Iterable<File> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

void main() {
  test('glass stays on the layer that floats', () {
    // `GlassButton` is deliberately not matched: a button *is* the functional
    // layer wherever it appears, which is why any feature may use one. It is
    // the surfaces that are restricted.
    final glassSurfaces = RegExp(r'\bGlass(Surface|Sheet|Layer)\b');
    final offenders = <String>[];

    for (final file in _dartFiles()) {
      if (_functional.containsKey(file.path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (glassSurfaces.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'Content is opaque: use ContentSurface. Glass belongs to what '
            'floats above content — bars, sheets, dialogs, controls. If this '
            'really is a floating surface, add the file to _functional with '
            'the reason.\n${offenders.join("\n")}');
  });

  test('no hand-painted surfaces outside either material', () {
    final offenders = <String>[];

    for (final file in _dartFiles()) {
      if (_rawSurfaceAllowed.containsKey(file.path)) continue;
      if (file.path == 'lib/core/ios/glass.dart') continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        final decorated = line.contains('decoration: BoxDecoration(') &&
            _hasColourWithin(lines, i);
        final coloured = RegExp(r'\bMaterial\($').hasMatch(line.trim()) &&
            i + 1 < lines.length &&
            lines[i + 1].contains('color:') &&
            !lines[i + 1].contains('transparent');
        if (decorated || coloured) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'These paint a surface by hand. Use ContentSurface (content) '
            'or GlassSurface (floating), or add the file to '
            '_rawSurfaceAllowed with the reason it must stay literal.\n'
            '${offenders.join("\n")}');
  });
}

/// Whether the `BoxDecoration(` opened at [start] sets a colour, looking only
/// at the next few lines — enough for a decoration, short enough not to run
/// into the widget's children.
bool _hasColourWithin(List<String> lines, int start) {
  for (var i = start; i < start + 4 && i < lines.length; i++) {
    if (lines[i].contains('color:') && !lines[i].contains('border'))
      return true;
    if (lines[i].contains('),') && i > start) return false;
  }
  return false;
}
