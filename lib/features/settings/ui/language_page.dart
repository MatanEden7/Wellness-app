import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

import '../../../services/language_service.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(currentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: l10n.back,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: AppLanguage.values.map((lang) {
            final isSelected = lang == current;
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
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: isSelected ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      lang == AppLanguage.english ? '🇺🇸' : '🇮🇱',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                title: Text(
                  lang.displayName,
                  style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal),
                ),
                subtitle: Text(
                  lang == AppLanguage.english
                      ? l10n.leftToRight
                      : l10n.rightToLeft,
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () async {
                  await ref
                      .read(currentLanguageProvider.notifier)
                      .setLanguage(lang);
                  if (context.mounted) context.pop();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
