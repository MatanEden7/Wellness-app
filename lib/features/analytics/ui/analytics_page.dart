import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              titleSpacing: UIConstants.screenHorizontalPadding,
              title: Text(l10n.analyticsTitle),
              centerTitle: false,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _RangeSelectorHeader(
                child: _RangeSelector(
                  value: range,
                  onChanged: (next) =>
                      ref.read(analyticsRangeProvider.notifier).state = next,
                ),
              ),
            ),
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
                          child: Center(child: CircularProgressIndicator()),
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
        ),
      ),
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

/// The W / M / 6M / Y control.
class _RangeSelector extends StatelessWidget {
  final AnalyticsRange value;
  final ValueChanged<AnalyticsRange> onChanged;

  const _RangeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.screenHorizontalPadding,
        vertical: 8,
      ),
      color: theme.scaffoldBackgroundColor,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            for (final range in AnalyticsRange.values)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(range),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: range == value ? theme.cardColor : null,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      range.shortLabelFor(AppLocalizations.of(context)!),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight:
                            range == value ? FontWeight.w600 : FontWeight.w400,
                        color: range == value
                            ? theme.textTheme.bodyLarge?.color
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RangeSelectorHeader extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _RangeSelectorHeader({required this.child});

  static const double _height = 52;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      SizedBox(height: _height, child: child);

  @override
  bool shouldRebuild(_RangeSelectorHeader old) => old.child != child;
}
