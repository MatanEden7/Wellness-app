import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

import '../../../core/ios/app_scaffold.dart';
import '../../../core/ios/inset_list.dart';
import '../../../core/theme.dart';
import '../../../services/theme_service.dart';

class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = ref.watch(currentThemeProvider);

    return AppScaffold.child(
      title: l10n.theme,
      backTooltip: l10n.back,
      // An iOS single-choice list: one grouped section, a checkmark on the
      // selected row. Each option used to be its own outlined Card, which is
      // how a nine-item picker ended up 900pt tall.
      child: InsetSection(
        children: [
          for (final theme in AppThemeKind.values)
            InsetRow(
              title: _label(context, theme),
              subtitle: _description(context, theme),
              onTap: () async {
                await ref.read(currentThemeProvider.notifier).setTheme(theme);
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _previewColor(theme),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Theme.of(context).dividerColor, width: 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 20,
                    child: theme == currentTheme
                        ? Icon(CupertinoIcons.check_mark,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _previewColor(AppThemeKind theme) {
    switch (theme) {
      case AppThemeKind.light:
        return Colors.white;
      case AppThemeKind.dark:
        return const Color(0xFF1A1A2E);
      case AppThemeKind.gold:
        return const Color(0xFFFFD700);
      case AppThemeKind.ocean:
        return const Color(0xFF0EA5E9);
      case AppThemeKind.forest:
        return const Color(0xFF10B981);
      case AppThemeKind.sunset:
        return const Color(0xFFFF6B35);
      case AppThemeKind.lavender:
        return const Color(0xFF9333EA);
      case AppThemeKind.midnight:
        return const Color(0xFF60A5FA);
      case AppThemeKind.custom:
        return Colors.deepPurple;
    }
  }

  String _label(BuildContext context, AppThemeKind theme) {
    final l10n = AppLocalizations.of(context)!;
    switch (theme) {
      case AppThemeKind.light:
        return l10n.light;
      case AppThemeKind.dark:
        return l10n.dark;
      case AppThemeKind.gold:
        return l10n.gold;
      case AppThemeKind.ocean:
        return 'Ocean';
      case AppThemeKind.forest:
        return 'Forest';
      case AppThemeKind.sunset:
        return 'Sunset';
      case AppThemeKind.lavender:
        return 'Lavender';
      case AppThemeKind.midnight:
        return 'Midnight';
      case AppThemeKind.custom:
        return 'Custom';
    }
  }

  String _description(BuildContext context, AppThemeKind theme) {
    final l10n = AppLocalizations.of(context)!;
    switch (theme) {
      case AppThemeKind.light:
        return l10n.cleanAndBright;
      case AppThemeKind.dark:
        return l10n.easyOnEyes;
      case AppThemeKind.gold:
        return l10n.luxuryGold;
      case AppThemeKind.ocean:
        return 'Calming blues & teals';
      case AppThemeKind.forest:
        return 'Natural & balanced greens';
      case AppThemeKind.sunset:
        return 'Warm & energetic';
      case AppThemeKind.lavender:
        return 'Mindful & creative';
      case AppThemeKind.midnight:
        return 'Sophisticated dark blue';
      case AppThemeKind.custom:
        return 'Customize your own colors';
    }
  }
}
