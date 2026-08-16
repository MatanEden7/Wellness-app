import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../domain/models.dart';
import '../../meals/data/repositories.dart';
import '../../meals/domain/models.dart' as meal_models;
import '../../workouts/data/repositories.dart';
import '../../workouts/domain/models.dart' as workout_models;
import '../../sleep/data/repositories.dart';
import '../../sleep/domain/models.dart' as sleep_models;
import '../data/calendar_service.dart';
import '../../../data/db/drift_database.dart';
import '../../../core/ios/glass.dart';
import '../../../core/design/tokens.dart';
import '../../../core/ios/feedback.dart';
import '../../../core/ios/pickers.dart';

/// The weekdays a weekly event should repeat on.
///
/// Falls back to the weekday of the event's own date when the user picked
/// "Weekly" but never tapped a day chip. An empty list matches no weekday at
/// all, so the event silently produced zero occurrences and looked like
/// weekly recurrence was broken.
List<int> _weeklyDaysOrDefault(Set<int> selected, DateTime scheduledAt) {
  if (selected.isNotEmpty) return selected.toList()..sort();
  return [scheduledAt.weekday];
}

class EventSchedulingDialog extends HookConsumerWidget {
  final DateTime? initialDate;
  final EventType? initialType;
  final ScheduledEvent? existingEvent;

  const EventSchedulingDialog({
    super.key,
    this.initialDate,
    this.initialType,
    this.existingEvent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // State
    final selectedType =
        useState(existingEvent?.type ?? initialType ?? EventType.meal);
    final titleController =
        useTextEditingController(text: existingEvent?.title);
    final descriptionController =
        useTextEditingController(text: existingEvent?.description);
    final selectedDate =
        useState(existingEvent?.scheduledAt ?? initialDate ?? DateTime.now());
    final selectedTime = useState(
        TimeOfDay.fromDateTime(existingEvent?.scheduledAt ?? DateTime.now()));
    final selectedTemplate = useState<String?>(existingEvent?.templateId);
    final recurrenceType =
        useState(existingEvent?.recurrenceType ?? RecurrenceType.none);
    final selectedDays =
        useState<Set<int>>(existingEvent?.recurrenceDays.toSet() ?? {});
    final customInterval = useState<int>(existingEvent?.customInterval ?? 1);
    final hasEndDate = useState<bool>(existingEvent?.recurrenceEndDate != null);
    final endDate = useState<DateTime?>(existingEvent?.recurrenceEndDate);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(14),
        showBorder: false,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              GlassSurface.tinted(
                color: theme.colorScheme.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          existingEvent != null
                              ? l10n.editEvent
                              : l10n.scheduleEvent,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: l10n.close,
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Type Selector
                      Text(l10n.eventType, style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      SegmentedButton<EventType>(
                        // Text-only, like a UISegmentedControl. Three segments
                        // with both an icon and a label don't fit the dialog
                        // width, so "Workout" wrapped to "Work / out". The
                        // selected segment is already obvious from its fill, so
                        // the checkmark is dropped too.
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: EventType.meal,
                            label: Text(l10n.meal, maxLines: 1),
                          ),
                          ButtonSegment(
                            value: EventType.workout,
                            label: Text(l10n.workout, maxLines: 1),
                          ),
                          ButtonSegment(
                            value: EventType.sleep,
                            // "Sleep", not "Sleep Entry" -- it sits under an
                            // "Event Type" label, so the shorter form is clear.
                            label: Text(l10n.sleep, maxLines: 1),
                          ),
                        ],
                        selected: {selectedType.value},
                        onSelectionChanged: (value) {
                          selectedType.value = value.first;
                          selectedTemplate.value = null;
                          titleController.text = '';
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Template/Existing Item Selector (for meals and workouts)
                      if (selectedType.value != EventType.sleep) ...[
                        Text(
                          selectedType.value == EventType.meal
                              ? l10n.selectMealTemplate
                              : l10n.selectWorkoutTemplate,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _TemplateAndExistingSelector(
                          type: selectedType.value,
                          selectedTemplateId: selectedTemplate.value,
                          onTemplateSelected: (id, name) {
                            selectedTemplate.value = id;
                            if (titleController.text.isEmpty) {
                              titleController.text = name;
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Title
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: l10n.title,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Description
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: l10n.description,
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Date & Time
                      Row(
                        children: [
                          Expanded(
                            child: _DatePicker(
                              label: l10n.date,
                              date: selectedDate.value,
                              onDateSelected: (date) =>
                                  selectedDate.value = date,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _TimePicker(
                              label: l10n.time,
                              time: selectedTime.value,
                              onTimeSelected: (time) =>
                                  selectedTime.value = time,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Recurrence
                      Text(l10n.repeat, style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<RecurrenceType>(
                        initialValue: recurrenceType.value,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: RecurrenceType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getRecurrenceLabel(type, l10n)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            recurrenceType.value = value;
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Weekly day selector
                      if (recurrenceType.value == RecurrenceType.weekly) ...[
                        Text(l10n.selectDays, style: theme.textTheme.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        _WeekdaySelector(
                          selectedDays: selectedDays.value,
                          onDaysChanged: (days) => selectedDays.value = days,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      // Custom interval selector
                      if (recurrenceType.value == RecurrenceType.custom) ...[
                        Row(
                          children: [
                            Text(l10n.every, style: theme.textTheme.bodyMedium),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                controller: TextEditingController(
                                  text: customInterval.value.toString(),
                                ),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null && parsed > 0) {
                                    customInterval.value = parsed;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.days, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      // End date option
                      if (recurrenceType.value != RecurrenceType.none) ...[
                        CheckboxListTile(
                          title: Text(l10n.hasEndDate),
                          value: hasEndDate.value,
                          onChanged: (value) {
                            hasEndDate.value = value ?? false;
                            if (!hasEndDate.value) {
                              endDate.value = null;
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (hasEndDate.value) ...[
                          _DatePicker(
                            label: l10n.endDate,
                            date: endDate.value ??
                                selectedDate.value
                                    .add(const Duration(days: 30)),
                            onDateSelected: (date) => endDate.value = date,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GlassButton(
                      minHeight: Sizes.control,
                      borderRadius: BorderRadius.circular(18),
                      padding: const EdgeInsets.symmetric(
                          horizontal: Space.md, vertical: Space.sm),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GlassButton(
                      prominent: true,
                      onPressed: () async {
                        if (titleController.text.isEmpty) {
                          showAppError(context, l10n.titleRequired);
                          return;
                        }

                        final scheduledDateTime = DateTime(
                          selectedDate.value.year,
                          selectedDate.value.month,
                          selectedDate.value.day,
                          selectedTime.value.hour,
                          selectedTime.value.minute,
                        );

                        // The event is built first and the data second, never the
                        // other way round. The logged row has to carry the
                        // event's id in `sourceEventId` -- that link is the only
                        // thing stopping the calendar showing the plan and the
                        // log as two rows for one activity (ISSUES #57, and
                        // again as #75 when this block created the data first
                        // and the event could not be referenced yet).
                        final draft = existingEvent != null
                            ? existingEvent!.copyWith(
                                title: titleController.text,
                                description: descriptionController.text.isEmpty
                                    ? null
                                    : descriptionController.text,
                                type: selectedType.value,
                                scheduledAt: scheduledDateTime,
                                recurrenceType: recurrenceType.value,
                                recurrenceDays: recurrenceType.value ==
                                        RecurrenceType.weekly
                                    ? _weeklyDaysOrDefault(
                                        selectedDays.value, selectedDate.value)
                                    : [],
                                customInterval: recurrenceType.value ==
                                        RecurrenceType.custom
                                    ? customInterval.value
                                    : null,
                                recurrenceEndDate:
                                    hasEndDate.value ? endDate.value : null,
                                templateId: selectedTemplate.value,
                              )
                            : ScheduledEvent.create(
                                title: titleController.text,
                                description: descriptionController.text.isEmpty
                                    ? null
                                    : descriptionController.text,
                                type: selectedType.value,
                                scheduledAt: scheduledDateTime,
                                recurrenceType: recurrenceType.value,
                                recurrenceDays: recurrenceType.value ==
                                        RecurrenceType.weekly
                                    ? _weeklyDaysOrDefault(
                                        selectedDays.value, selectedDate.value)
                                    : [],
                                customInterval: recurrenceType.value ==
                                        RecurrenceType.custom
                                    ? customInterval.value
                                    : null,
                                recurrenceEndDate:
                                    hasEndDate.value ? endDate.value : null,
                                templateId: selectedTemplate.value,
                              );

                        // Anything scheduled for (near enough) now is logged
                        // straight away, linked back to the event above.
                        String? dataId;
                        final isImmediate = scheduledDateTime.isBefore(
                            DateTime.now().add(const Duration(minutes: 5)));

                        if (isImmediate) {
                          // Sleep needs no template; meals and workouts copy from
                          // one.
                          if (selectedType.value == EventType.sleep ||
                              selectedTemplate.value != null) {
                            dataId = await _createDataFromTemplate(
                              ref,
                              selectedType.value,
                              selectedTemplate.value ?? 'no-template',
                              scheduledDateTime,
                              titleController.text,
                              descriptionController.text.isEmpty
                                  ? null
                                  : descriptionController.text,
                              sourceEventId: draft.id,
                            );
                          }
                        }

                        // Existing metadata is merged rather than replaced: a
                        // recurring event records its completed / missed /
                        // skipped occurrence dates there, and overwriting the map
                        // with a bare {'dataId': ...} would erase that history on
                        // any edit.
                        final event = dataId == null
                            ? draft
                            : draft.copyWith(metadata: {
                                ...?draft.metadata,
                                'dataId': dataId,
                              });

                        if (existingEvent != null) {
                          await ref
                              .read(calendarStateProvider.notifier)
                              .updateEvent(event);
                        } else {
                          await ref
                              .read(calendarStateProvider.notifier)
                              .addEvent(event);
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop(event);
                        }
                      },
                      child: Text(
                          existingEvent != null ? l10n.save : l10n.schedule),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRecurrenceLabel(RecurrenceType type, AppLocalizations l10n) {
    switch (type) {
      case RecurrenceType.none:
        return l10n.noRepeat;
      case RecurrenceType.daily:
        return l10n.daily;
      case RecurrenceType.weekly:
        return l10n.weekly;
      case RecurrenceType.monthly:
        return l10n.monthly;
      case RecurrenceType.custom:
        return l10n.custom;
    }
  }
}

class _TemplateAndExistingSelector extends HookConsumerWidget {
  final EventType type;
  final String? selectedTemplateId;
  final Function(String id, String name) onTemplateSelected;

  const _TemplateAndExistingSelector({
    required this.type,
    required this.selectedTemplateId,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedTab = useState(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab selector
        Row(
          children: [
            Expanded(
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(AppLocalizations.of(context)!.templates),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(AppLocalizations.of(context)!.recent),
                  ),
                ],
                selected: {selectedTab.value},
                onSelectionChanged: (value) {
                  selectedTab.value = value.first;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Content based on selected tab
        if (selectedTab.value == 0)
          _buildTemplateSelector(context, ref, l10n)
        else
          _buildExistingSelector(context, ref, l10n),
      ],
    );
  }

  Widget _buildTemplateSelector(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    if (type == EventType.meal) {
      return FutureBuilder<List<MealTemplateData>>(
        future: ref.read(databaseProvider).getAllMealTemplates(),
        builder: (context, snapshot) {
          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Text(
              l10n.noMealTemplates,
              style: Theme.of(context).textTheme.bodySmall,
            );
          }

          return DropdownButtonFormField<String>(
            initialValue: selectedTemplateId,
            // Names like "Upper Body (Upper/Lower Split)" are wider than the
            // dialog. isExpanded lets the item fill the field so the Text can
            // ellipsize instead of overflowing the row.
            isExpanded: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.selectTemplate,
            ),
            items: templates.map((template) {
              return DropdownMenuItem(
                value: template.id,
                child: Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final template = templates.firstWhere((t) => t.id == value);
                onTemplateSelected(value, template.name);
              }
            },
          );
        },
      );
    } else {
      // Workout templates
      return FutureBuilder<List<WorkoutTemplateData>>(
        future: ref.read(databaseProvider).getAllWorkoutTemplates(),
        builder: (context, snapshot) {
          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Text(
              l10n.noWorkoutTemplates,
              style: Theme.of(context).textTheme.bodySmall,
            );
          }

          return DropdownButtonFormField<String>(
            initialValue: selectedTemplateId,
            // Names like "Upper Body (Upper/Lower Split)" are wider than the
            // dialog. isExpanded lets the item fill the field so the Text can
            // ellipsize instead of overflowing the row.
            isExpanded: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.selectTemplate,
            ),
            items: templates.map((template) {
              return DropdownMenuItem(
                value: template.id,
                child: Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final template = templates.firstWhere((t) => t.id == value);
                onTemplateSelected(value, template.name);
              }
            },
          );
        },
      );
    }
  }

  Widget _buildExistingSelector(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    if (type == EventType.meal) {
      // Show recent meals
      return FutureBuilder<List<MealData>>(
        future: ref.read(databaseProvider).getRecentMeals(limit: 20),
        builder: (context, snapshot) {
          final meals = snapshot.data ?? [];

          if (meals.isEmpty) {
            return Text(
              AppLocalizations.of(context)!.noRecentMeals,
              style: Theme.of(context).textTheme.bodySmall,
            );
          }

          return DropdownButtonFormField<String>(
            initialValue: selectedTemplateId?.startsWith('meal_') == true
                ? selectedTemplateId
                : null,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: AppLocalizations.of(context)!.calendarSelectRecentMeal,
            ),
            isExpanded: true,
            items: meals.map((meal) {
              return DropdownMenuItem(
                value: 'meal_${meal.id}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      AppDateUtils.formatDate(
                          AppDateUtils.intToDate(meal.date)),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final meal = meals.firstWhere((m) => 'meal_${m.id}' == value);
                onTemplateSelected(value, meal.name);
              }
            },
          );
        },
      );
    } else {
      // Show recent workouts
      return FutureBuilder<List<WorkoutSessionData>>(
        future: ref.read(databaseProvider).getRecentWorkoutSessions(limit: 20),
        builder: (context, snapshot) {
          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Text(
              AppLocalizations.of(context)!.noRecentWorkouts,
              style: Theme.of(context).textTheme.bodySmall,
            );
          }

          return FutureBuilder<List<WorkoutTemplateData>>(
            future: ref.read(databaseProvider).getAllWorkoutTemplates(),
            builder: (context, templateSnapshot) {
              final templates = templateSnapshot.data ?? [];

              return DropdownButtonFormField<String>(
                initialValue: selectedTemplateId,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText:
                      AppLocalizations.of(context)!.calendarSelectRecentWorkout,
                ),
                isExpanded: true,
                items: sessions.map((session) {
                  final template = templates
                      .where((t) => t.id == session.templateId)
                      .firstOrNull;
                  final displayName = template?.name ?? 'Custom Workout';

                  return DropdownMenuItem(
                    value: session.templateId ?? session.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppDateUtils.formatDate(session.startedAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final session = sessions
                        .firstWhere((s) => (s.templateId ?? s.id) == value);
                    final template = templates
                        .where((t) => t.id == session.templateId)
                        .firstOrNull;
                    final displayName = template?.name ?? 'Custom Workout';
                    onTemplateSelected(value, displayName);
                  }
                },
              );
            },
          );
        },
      );
    }
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime date;
  final Function(DateTime) onDateSelected;

  const _DatePicker({
    required this.label,
    required this.date,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showAppDatePicker(
          context: context,
          initial: date,
          first: DateTime.now().subtract(const Duration(days: 365)),
          last: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 34, minHeight: 34),
        ),
        // A compact, locale-aware date. The shared AppDateUtils.formatDate is
        // deliberately not used here: it is "yyyy-MM-dd" (which dateToInt
        // parses, so it must not change), and at that length the date wrapped
        // onto two lines in this half-width field -- "2026-08-0 / 3".
        child: Text(
          DateFormat.yMd(Localizations.localeOf(context).toString())
              .format(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final Function(TimeOfDay) onTimeSelected;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showAppTimePicker(
          context: context,
          initial: time,
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.access_time, size: 18),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 34, minHeight: 34),
        ),
        child: Text(
          time.format(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final Function(Set<int>) onDaysChanged;

  const _WeekdaySelector({
    required this.selectedDays,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Wrap(
      spacing: AppSpacing.xs,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isSelected = selectedDays.contains(dayNumber);

        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          onSelected: (selected) {
            final newDays = Set<int>.from(selectedDays);
            if (selected) {
              newDays.add(dayNumber);
            } else {
              newDays.remove(dayNumber);
            }
            onDaysChanged(newDays);
          },
        );
      }),
    );
  }
}

// Helper function to create actual data entries from templates or existing items
/// Writes the real meal / session / sleep entry for an event being scheduled
/// for right now.
///
/// [sourceEventId] is **required**, not optional: without it the created row
/// has no link back to the event, and `CalendarService` renders both the plan
/// and the log as separate rows -- the ISSUES #57 symptom, which reached
/// production a second time through exactly this function (#75). Making it
/// required also forces the caller to build the event *before* calling here,
/// which is the ordering the bug came from.
Future<String?> _createDataFromTemplate(
  WidgetRef ref,
  EventType type,
  String templateId,
  DateTime scheduledAt,
  String title,
  String? description, {
  required String sourceEventId,
}) async {
  try {
    final database = ref.read(databaseProvider);
    final dateInt = AppDateUtils.dateToInt(scheduledAt);

    switch (type) {
      case EventType.meal:
        // Check if this is copying from an existing meal or a template
        if (templateId.startsWith('meal_')) {
          // Copy from existing meal
          final existingMealId = templateId.replaceFirst('meal_', '');
          final existingMeal = await ref
              .read(mealsRepositoryProvider)
              .getMealById(existingMealId);

          if (existingMeal != null) {
            final newMeal = meal_models.Meal.create(
              date: dateInt,
              name: title,
              note: description ?? existingMeal.note,
            );

            // Copy items from existing meal
            final items = existingMeal.items
                .map((item) => meal_models.MealItem(
                      id: const Uuid().v4(),
                      mealId: newMeal.id,
                      foodId: item.foodId,
                      amount: item.amount,
                      kcal: item.kcal,
                      protein: item.protein,
                      carbs: item.carbs,
                      fat: item.fat,
                    ))
                .toList();

            final mealWithItems = newMeal.copyWith(items: items);
            await ref
                .read(mealsRepositoryProvider)
                .createMeal(mealWithItems, sourceEventId: sourceEventId);
            return newMeal.id;
          }
        } else {
          // Create from template
          final template = await database.getMealTemplateById(templateId);
          if (template == null) return null;

          final meal = meal_models.Meal.create(
            date: dateInt,
            name: title,
            note: description,
          );

          // Copy template items
          final templateItems =
              await database.getMealTemplateItemsByTemplateId(templateId);
          final items = <meal_models.MealItem>[];

          for (final item in templateItems) {
            final food = await database.getFoodById(item.foodId);
            if (food != null) {
              items.add(meal_models.MealItem.create(
                mealId: meal.id,
                foodId: item.foodId,
                amount: item.amount,
                food: meal_models.FoodItem(
                  id: food.id,
                  name: food.name,
                  brand: food.brand,
                  unit: food.unit,
                  kcalPerUnit: food.kcalPerUnit,
                  proteinPerUnit: food.proteinPerUnit,
                  carbsPerUnit: food.carbsPerUnit,
                  fatPerUnit: food.fatPerUnit,
                  isStarter: food.isStarter,
                  createdAt: food.createdAt,
                  updatedAt: food.updatedAt,
                ),
              ));
            }
          }

          final mealWithItems = meal.copyWith(items: items);
          await ref
              .read(mealsRepositoryProvider)
              .createMeal(mealWithItems, sourceEventId: sourceEventId);
          return meal.id;
        }
        break;

      case EventType.workout:
        // Create workout session from template
        final session = workout_models.WorkoutSession.create(
          templateId: templateId,
          note: description,
        );

        await ref
            .read(workoutSessionsRepositoryProvider)
            .createSession(session, sourceEventId: sourceEventId);
        return session.id;

      case EventType.sleep:
        // Create sleep entry
        final sleep = sleep_models.SleepEntry.create(
          startedAt: scheduledAt,
          note: description,
        );

        await ref
            .read(sleepRepositoryProvider)
            .createEntry(sleep, sourceEventId: sourceEventId);
        return sleep.id;
    }
  } catch (e) {
    debugPrint('Error creating data from template: $e');
    return null;
  }
  return null;
}
