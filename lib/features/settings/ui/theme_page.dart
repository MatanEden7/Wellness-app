import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

import '../../../shell/platform_page.dart';
import '../../../core/ios/inset_list.dart';
import '../../../core/theme.dart';
import '../../../services/theme_service.dart';

class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = ref.watch(currentThemeProvider);

    return PlatformChildPage(
      chrome: PageChrome(
        title: l10n.theme,
        backTooltip: l10n.back,
      ),
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
        return l10n.themeOcean;
      case AppThemeKind.forest:
        return l10n.themeForest;
      case AppThemeKind.sunset:
        return l10n.themeSunset;
      case AppThemeKind.lavender:
        return l10n.themeLavender;
      case AppThemeKind.midnight:
        return l10n.themeMidnight;
      case AppThemeKind.custom:
        return l10n.themeCustom;
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
        return l10n.themeOceanDesc;
      case AppThemeKind.forest:
        return l10n.themeForestDesc;
      case AppThemeKind.sunset:
        return l10n.themeSunsetDesc;
      case AppThemeKind.lavender:
        return l10n.themeLavenderDesc;
      case AppThemeKind.midnight:
        return l10n.themeMidnightDesc;
      case AppThemeKind.custom:
        return l10n.themeCustomDesc;
    }
  }
}
