import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

import '../../../shell/platform_page.dart';
import '../../../core/ios/inset_list.dart';
import '../../../data/db/drift_database.dart';
import '../../../services/content_language_service.dart';
import '../../../services/language_service.dart';
import '../../../services/user_profile_service.dart';
import '../../calendar/data/calendar_service.dart';

class LanguagePage extends ConsumerStatefulWidget {
  const LanguagePage({super.key});

  @override
  ConsumerState<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends ConsumerState<LanguagePage> {
  /// True while content is being moved across. The rows are disabled rather
  /// than merely ignored: a second tap partway through would start a competing
  /// regeneration over the same templates.
  bool _switching = false;

  /// Changes the language, then moves every stored row into it.
  ///
  /// Both halves are needed and they are not the same thing. `setLanguage`
  /// changes the *chrome* -- ARB strings, tag labels, text direction -- which
  /// is a preference the UI reads on every build. Content is not read that
  /// way: a food row holds one name, written when the catalog was seeded, so
  /// without the second half a Hebrew UI would keep listing "Chicken Breast".
  ///
  /// Doing it here rather than automatically anywhere else is the point.
  /// Content only ever changes language because someone asked it to, on this
  /// screen, so a plan can never rename itself under a user mid-week.
  Future<void> _select(AppLanguage language) async {
    if (_switching) return;
    final current = ref.read(currentLanguageProvider);
    if (language == current) {
      context.pop();
      return;
    }

    setState(() => _switching = true);
    // Read every provider before the first await: this widget can be disposed
    // while the switch runs, and `ref` is not safe to touch afterwards.
    final notifier = ref.read(currentLanguageProvider.notifier);
    final service = ContentLanguageService(
      ref.read(databaseProvider),
      ref.read(userProfileServiceProvider),
      ref.read(calendarServiceProvider),
      ref.read(calendarStateProvider.notifier),
    );

    await notifier.setLanguage(language);
    await service.switchTo(language);

    if (mounted) {
      setState(() => _switching = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(currentLanguageProvider);

    // Same single-choice shape as the theme picker: one grouped section, a
    // checkmark on the selected row.
    return PlatformChildPage(
      chrome: PageChrome(
        title: l10n.language,
        backTooltip: l10n.back,
      ),
      child: InsetSection(
        children: [
          for (final lang in AppLanguage.values)
            InsetRow(
              title: lang.displayName,
              subtitle: lang == AppLanguage.english
                  ? l10n.leftToRight
                  : l10n.rightToLeft,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang == AppLanguage.english ? '🇺🇸' : '🇮🇱',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 20,
                    child: _switching && lang != current
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CupertinoActivityIndicator(radius: 8),
                          )
                        : lang == current
                            ? Icon(CupertinoIcons.check_mark,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                  ),
                ],
              ),
              onTap: _switching ? null : () => _select(lang),
            ),
        ],
      ),
    );
  }
}
