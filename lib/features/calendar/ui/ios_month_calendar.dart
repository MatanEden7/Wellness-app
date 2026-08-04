
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/date_utils.dart';
import '../domain/models.dart';

/// A continuously-scrolling month grid modelled on the iOS Calendar app.
///
/// Deliberately hand-rolled rather than themed on top of `table_calendar`:
/// that package paginates one month per `PageView` page, and the defining
/// interaction of the iPhone calendar is *continuous* vertical scrolling
/// through months with a pinned weekday header. That can't be restyled in.
///
/// Colours come from the active [ColorScheme] rather than iOS's hardcoded red,
/// so the app's nine themes keep working; the *shapes*, sizing and typography
/// are what make it read as iOS.
class IosMonthCalendar extends StatefulWidget {
  const IosMonthCalendar({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.eventsForDay,
    required this.colorForType,
    required this.onDaySelected,
    required this.onMonthChanged,
    this.weekView = false,
    this.firstMonth,
    this.lastMonth,
  });

  final DateTime? selectedDate;
  final DateTime focusedDate;

  /// Events already filtered by the caller (type / planned / completed).
  final List<ScheduledEvent> Function(DateTime day) eventsForDay;

  /// The colour for an event type. Supplied by the caller so the dots match
  /// the user's configured section colours rather than the theme's palette.
  final Color Function(EventType type) colorForType;

  final ValueChanged<DateTime> onDaySelected;

  /// Fires when a different month scrolls into view, so the caller can page in
  /// that month's events.
  final ValueChanged<DateTime> onMonthChanged;

  /// Collapses to the single week containing [focusedDate].
  final bool weekView;

  final DateTime? firstMonth;
  final DateTime? lastMonth;

  @override
  State<IosMonthCalendar> createState() => _IosMonthCalendarState();
}

class _IosMonthCalendarState extends State<IosMonthCalendar> {
  // iOS-ish metrics. Day cells are >=44pt so they stay comfortable tap targets.
  static const double _dayCellHeight = 46;
  static const double _monthHeaderHeight = 44;
  static const double _monthBottomGap = 8;
  static const double _weekdayHeaderHeight = 30;

  late final DateTime _firstMonth;
  late final DateTime _lastMonth;
  late final int _monthCount;
  ScrollController? _controller;
  int _lastReportedMonthIndex = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _firstMonth = _monthOf(widget.firstMonth ?? DateTime(now.year - 3, now.month));
    _lastMonth = _monthOf(widget.lastMonth ?? DateTime(now.year + 3, now.month));
    _monthCount = _monthsBetween(_firstMonth, _lastMonth) + 1;
  }

  @override
  void didUpdateWidget(covariant IosMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jumping months from outside (e.g. a "today" action) should move the list.
    if (!widget.weekView &&
        _monthOf(oldWidget.focusedDate) != _monthOf(widget.focusedDate)) {
      _scrollToMonth(_monthOf(widget.focusedDate));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

  static int _monthsBetween(DateTime a, DateTime b) =>
      (b.year - a.year) * 12 + (b.month - a.month);

  DateTime _monthAt(int index) =>
      DateTime(_firstMonth.year, _firstMonth.month + index);

  /// Number of week rows a month occupies with a Sunday-first grid.
  static int _weeksInMonth(DateTime month) {
    final leading = _leadingBlanks(month);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    return ((leading + days) / 7).ceil();
  }

  /// Sunday-first: Sunday(7) -> 0, Monday(1) -> 1 ... Saturday(6) -> 6.
  static int _leadingBlanks(DateTime month) =>
      DateTime(month.year, month.month, 1).weekday % 7;

  double _monthExtent(int index) =>
      _monthHeaderHeight +
      _weeksInMonth(_monthAt(index)) * _dayCellHeight +
      _monthBottomGap;

  double _offsetOfMonth(int index) {
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += _monthExtent(i);
    }
    return offset;
  }

  void _scrollToMonth(DateTime month) {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;
    final index = _monthsBetween(_firstMonth, month).clamp(0, _monthCount - 1);
    controller.animateTo(
      _offsetOfMonth(index).clamp(0.0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// Reports the month occupying the top of the viewport so the caller can
  /// load its events. Debounced by index so it only fires on change.
  bool _onScroll(ScrollNotification notification) {
    if (widget.weekView) return false;
    final offset = notification.metrics.pixels;
    var running = 0.0;
    for (var i = 0; i < _monthCount; i++) {
      running += _monthExtent(i);
      if (offset < running) {
        if (i != _lastReportedMonthIndex) {
          _lastReportedMonthIndex = i;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onMonthChanged(_monthAt(i));
          });
        }
        break;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _WeekdayHeader(height: _weekdayHeaderHeight),
        Divider(height: 1, thickness: 1, color: theme.dividerColor.withOpacity(0.5)),
        Expanded(
          child: widget.weekView ? _buildWeek(context) : _buildMonthList(context),
        ),
      ],
    );
  }

  Widget _buildWeek(BuildContext context) {
    final start = AppDateUtils.startOfWeek(widget.focusedDate);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _dayCellHeight,
            child: Row(
              children: List.generate(7, (i) {
                final day = start.add(Duration(days: i));
                return Expanded(child: _buildDay(context, day, inMonth: true));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthList(BuildContext context) {
    _controller ??= ScrollController(
      initialScrollOffset: _offsetOfMonth(
        _monthsBetween(_firstMonth, _monthOf(widget.focusedDate))
            .clamp(0, _monthCount - 1),
      ),
    );

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView.builder(
        controller: _controller,
        // Heights are deterministic, so telling the sliver up front keeps
        // scrolling smooth and makes the initial jump to "today" exact.
        itemExtentBuilder: (index, _) =>
            index < _monthCount ? _monthExtent(index) : 0,
        itemCount: _monthCount,
        itemBuilder: (context, index) => _buildMonth(context, _monthAt(index)),
      ),
    );
  }

  Widget _buildMonth(BuildContext context, DateTime month) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();

    // iOS shows the year only when it isn't the current one.
    final label = month.year == now.year
        ? DateFormat.MMMM(locale).format(month)
        : DateFormat.yMMMM(locale).format(month);

    final leading = _leadingBlanks(month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final weeks = _weeksInMonth(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _monthHeaderHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  // The month a user is looking at is the one they care about.
                  color: month.month == now.month && month.year == now.year
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        for (var week = 0; week < weeks; week++)
          SizedBox(
            height: _dayCellHeight,
            child: Row(
              children: List.generate(7, (col) {
                final dayNumber = week * 7 + col - leading + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox.shrink());
                }
                return Expanded(
                  child: _buildDay(
                    context,
                    DateTime(month.year, month.month, dayNumber),
                    inMonth: true,
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: _monthBottomGap),
      ],
    );
  }

  Widget _buildDay(BuildContext context, DateTime day, {required bool inMonth}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = AppDateUtils.startOfDay(DateTime.now());
    final date = AppDateUtils.startOfDay(day);

    final isToday = date == today;
    final isSelected = widget.selectedDate != null &&
        AppDateUtils.startOfDay(widget.selectedDate!) == date;
    // Israeli convention, used by the rest of the app (weekly aggregates,
    // schedule generator). Muted rather than red so it can't be mistaken for
    // "today", which is what red means on this screen.
    final isWeekend =
        day.weekday == DateTime.friday || day.weekday == DateTime.saturday;

    final events = widget.eventsForDay(date);

    final Color numberColor;
    final Color? circleColor;
    if (isSelected && isToday) {
      circleColor = scheme.primary;
      numberColor = scheme.onPrimary;
    } else if (isSelected) {
      circleColor = scheme.onSurface;
      numberColor = scheme.surface;
    } else if (isToday) {
      circleColor = null;
      numberColor = scheme.primary;
    } else if (isWeekend) {
      circleColor = null;
      numberColor = scheme.onSurface.withOpacity(0.45);
    } else {
      circleColor = null;
      numberColor = scheme.onSurface;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString())
          .format(day),
      value: events.isEmpty ? null : '${events.length}',
      child: InkResponse(
        onTap: () => widget.onDaySelected(date),
        radius: 26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: circleColor == null
                  ? null
                  : BoxDecoration(color: circleColor, shape: BoxShape.circle),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 19,
                  // iOS bolds today and the selection, nothing else.
                  fontWeight: isToday || isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: numberColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(height: 3, child: _buildDots(context, events)),
          ],
        ),
      ),
    );
  }

  /// Up to three dots, coloured per event type -- the app already colour-codes
  /// meals/workouts/sleep, so the dots carry that through instead of iOS's
  /// single grey dot.
  Widget _buildDots(BuildContext context, List<ScheduledEvent> events) {
    if (events.isEmpty) return const SizedBox.shrink();

    final types = <EventType>[];
    for (final event in events) {
      if (!types.contains(event.type)) types.add(event.type);
    }
    final shown = types.take(3).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final type in shown)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: widget.colorForType(type),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }


}

/// Pinned S M T W T F S row, iOS-style: short, uppercase, letterspaced.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    // Any known Sunday; only the weekday name is used.
    final sunday = DateTime(2024, 1, 7);

    return SizedBox(
      height: height,
      child: Row(
        children: List.generate(7, (i) {
          final day = sunday.add(Duration(days: i));
          final isWeekend =
              day.weekday == DateTime.friday || day.weekday == DateTime.saturday;
          return Expanded(
            child: Center(
              child: Text(
                DateFormat.E(locale).format(day).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface
                      .withOpacity(isWeekend ? 0.35 : 0.55),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
