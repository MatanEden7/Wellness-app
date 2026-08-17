import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../shell/platform_page.dart';
import '../../../core/ios/controls.dart';
import '../../../core/ui_constants.dart';
import '../data/providers.dart';
import '../domain/analytics_range.dart';
import '../domain/analytics_view.dart';
import 'sections/body_weight_section.dart';
import 'sections/goals_section.dart';
import 'sections/insights_section.dart';
import 'sections/nutrition_section.dart';
import 'sections/sleep_section.dart';
import 'sections/strength_section.dart';
import 'sections/training_section.dart';
import 'widgets/analytics_card.dart';
import '../../../core/design/tokens.dart';

/// The analytics screen.
///
/// A large title, a pinned range control, then one scrolling column of cards.
/// Everything on it reads from a single [AnalyticsView] computed once per
/// range — no section queries anything itself, because seven sections each
/// watching their own stream would re-run the whole aggregation seven times a
/// frame.
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final range = ref.watch(analyticsRangeProvider);
    final viewAsync = ref.watch(analyticsViewProvider(range));

    return PlatformPage(
      chrome: PageChrome(
        title: l10n.analyticsTitle,
        // The 56 default, not the 52 this used to override it to. A segmented
        // control at 14pt fits in 52 with Latin glyphs and overflows it by a
        // pixel with Hebrew ones, which are taller at the same point size --
        // and the overflow stripe is the first thing a user sees on the
        // screen. There is nothing this control needs the extra 4px back for.
        pinnedHeaderHeight: 56,
        pinnedHeader: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.screenHorizontalPadding,
            vertical: Space.sm,
          ),
          child: AppSegmented<AnalyticsRange>(
            value: range,
            onChanged: (next) =>
                ref.read(analyticsRangeProvider.notifier).state = next,
            segments: {
              for (final r in AnalyticsRange.values) r: r.shortLabelFor(l10n),
            },
          ),
        ),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            UIConstants.screenHorizontalPadding,
            UIConstants.cardSpacing,
            UIConstants.screenHorizontalPadding,
            UIConstants.sectionSpacing,
          ),
          sliver: viewAsync.when(
            data: (view) => _Sections(view: view),
            // Keeps the last good view on screen while a recomputation
            // runs, rather than flashing a spinner every time a set is
            // logged in another tab.
            loading: () => viewAsync.hasValue
                ? _Sections(view: viewAsync.value!)
                : const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child:
                          Center(child: CupertinoActivityIndicator(radius: 14)),
                    ),
                  ),
            error: (error, _) => SliverToBoxAdapter(
              child: CardEmptyState(
                icon: Icons.error_outline,
                message: l10n.analyticsLoadError('$error'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Sections extends StatelessWidget {
  final AnalyticsView view;

  const _Sections({required this.view});

  @override
  Widget build(BuildContext context) {
    if (view.hasNoData) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: CardEmptyState(
            icon: Icons.insights_outlined,
            message: AppLocalizations.of(context)!.analyticsEmptyAll,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        GoalsSection(view: view),
        InsightsSection(view: view),
        NutritionSection(view: view),
        TrainingSection(view: view),
        StrengthSection(view: view),
        BodyWeightSection(view: view),
        SleepSection(view: view),
      ]),
    );
  }
}
