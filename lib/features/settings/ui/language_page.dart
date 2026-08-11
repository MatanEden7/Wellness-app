import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

import '../../../shell/platform_page.dart';
import '../../../core/ios/inset_list.dart';
import '../../../services/language_service.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    child: lang == current
                        ? Icon(CupertinoIcons.check_mark,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                ],
              ),
              onTap: () async {
                await ref
                    .read(currentLanguageProvider.notifier)
                    .setLanguage(lang);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
    );
  }
}
