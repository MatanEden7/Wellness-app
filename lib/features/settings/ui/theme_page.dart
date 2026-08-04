import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

import '../../../core/theme.dart';
import '../../../services/theme_service.dart';

class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = ref.watch(currentThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.theme),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: l10n.back,
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: AppThemeKind.values.length,
          itemBuilder: (context, index) {
            final theme = AppThemeKind.values[index];
            final isSelected = theme == currentTheme;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: isSelected ? 3 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _previewColor(theme),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).dividerColor, width: 1),
                  ),
                ),
                title: Text(
                  _label(context, theme),
                  style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal),
                ),
                subtitle: Text(_description(context, theme)),
                trailing: isSelected
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () async {
                  await ref
                      .read(currentThemeProvider.notifier)
                      .setTheme(theme);
                },
              ),
            );
          },
        ),
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
