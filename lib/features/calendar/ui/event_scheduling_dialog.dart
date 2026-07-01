import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final selectedType = useState(existingEvent?.type ?? initialType ?? EventType.meal);
    final titleController = useTextEditingController(text: existingEvent?.title);
    final descriptionController = useTextEditingController(text: existingEvent?.description);
    final selectedDate = useState(existingEvent?.scheduledAt ?? initialDate ?? DateTime.now());
    final selectedTime = useState(TimeOfDay.fromDateTime(existingEvent?.scheduledAt ?? DateTime.now()));
    final selectedTemplate = useState<String?>(existingEvent?.templateId);
    final recurrenceType = useState(existingEvent?.recurrenceType ?? RecurrenceType.none);
    final selectedDays = useState<Set<int>>(existingEvent?.recurrenceDays.toSet() ?? {});
    final customInterval = useState<int>(existingEvent?.customInterval ?? 1);
    final hasEndDate = useState<bool>(existingEvent?.recurrenceEndDate != null);
    final endDate = useState<DateTime?>(existingEvent?.recurrenceEndDate);
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      existingEvent != null ? l10n.editEvent : l10n.scheduleEvent,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
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
                      segments: [
                        ButtonSegment(
                          value: EventType.meal,
                          label: Text(l10n.meal),
                          icon: const Icon(Icons.restaurant),
                        ),
                        ButtonSegment(
                          value: EventType.workout,
                          label: Text(l10n.workout),
                          icon: const Icon(Icons.fitness_center),
                        ),
                        ButtonSegment(
                          value: EventType.sleep,
                          label: Text(l10n.sleepEntry),
                          icon: const Icon(Icons.bedtime),
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
                            onDateSelected: (date) => selectedDate.value = date,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _TimePicker(
                            label: l10n.time,
                            time: selectedTime.value,
                            onTimeSelected: (time) => selectedTime.value = time,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // Recurrence
                    Text(l10n.repeat, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<RecurrenceType>(
                      value: recurrenceType.value,
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
                          date: endDate.value ?? selectedDate.value.add(const Duration(days: 30)),
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
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.titleRequired)),
                        );
                        return;
                      }
                      
                      final scheduledDateTime = DateTime(
                        selectedDate.value.year,
                        selectedDate.value.month,
                        selectedDate.value.day,
                        selectedTime.value.hour,
                        selectedTime.value.minute,
                      );
                      
                      // Create the underlying data entry if scheduling for immediate execution
                      String? dataId;
                      final isImmediate = scheduledDateTime.isBefore(DateTime.now().add(const Duration(minutes: 5)));
                      
                      if (isImmediate) {
                        // For sleep, we don't need a template
                        // For meals/workouts, we need a template to copy from
                        if (selectedType.value == EventType.sleep || selectedTemplate.value != null) {
                          dataId = await _createDataFromTemplate(
                            ref,
                            selectedType.value,
                            selectedTemplate.value ?? 'no-template', // Sleep doesn't need template
                            scheduledDateTime,
                            titleController.text,
                            descriptionController.text.isEmpty ? null : descriptionController.text,
                          );
                        }
                      }
                      
                      final event = existingEvent != null
                          ? existingEvent!.copyWith(
                              title: titleController.text,
                              description: descriptionController.text.isEmpty ? null : descriptionController.text,
                              type: selectedType.value,
                              scheduledAt: scheduledDateTime,
                              recurrenceType: recurrenceType.value,
                              recurrenceDays: recurrenceType.value == RecurrenceType.weekly 
                                  ? selectedDays.value.toList() 
                                  : [],
                              customInterval: recurrenceType.value == RecurrenceType.custom 
                                  ? customInterval.value 
                                  : null,
                              recurrenceEndDate: hasEndDate.value ? endDate.value : null,
                              templateId: selectedTemplate.value,
                              metadata: dataId != null ? {'dataId': dataId} : null,
                            )
                          : ScheduledEvent.create(
                              title: titleController.text,
                              description: descriptionController.text.isEmpty ? null : descriptionController.text,
                              type: selectedType.value,
                              scheduledAt: scheduledDateTime,
                              recurrenceType: recurrenceType.value,
                              recurrenceDays: recurrenceType.value == RecurrenceType.weekly 
                                  ? selectedDays.value.toList() 
                                  : [],
                              customInterval: recurrenceType.value == RecurrenceType.custom 
                                  ? customInterval.value 
                                  : null,
                              recurrenceEndDate: hasEndDate.value ? endDate.value : null,
                              templateId: selectedTemplate.value,
                              metadata: dataId != null ? {'dataId': dataId} : null,
                            );
                      
                      if (existingEvent != null) {
                        await ref.read(calendarStateProvider.notifier).updateEvent(event);
                      } else {
                        await ref.read(calendarStateProvider.notifier).addEvent(event);
                      }
                      
                      if (context.mounted) {
                        Navigator.of(context).pop(event);
                      }
                    },
                    child: Text(existingEvent != null ? l10n.save : l10n.schedule),
                  ),
                ],
              ),
            ),
          ],
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
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Templates'),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Recent'),
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
  
  Widget _buildTemplateSelector(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
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
            value: selectedTemplateId,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.selectTemplate,
            ),
            items: templates.map((template) {
              return DropdownMenuItem(
                value: template.id,
                child: Text(template.name),
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
            value: selectedTemplateId,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.selectTemplate,
            ),
            items: templates.map((template) {
              return DropdownMenuItem(
                value: template.id,
                child: Text(template.name),
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
  
  Widget _buildExistingSelector(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    if (type == EventType.meal) {
      // Show recent meals
      return FutureBuilder<List<MealData>>(
        future: ref.read(databaseProvider).getRecentMeals(limit: 20),
        builder: (context, snapshot) {
          final meals = snapshot.data ?? [];
          
          if (meals.isEmpty) {
            return Text(
              'No recent meals',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
          
          return DropdownButtonFormField<String>(
            value: selectedTemplateId?.startsWith('meal_') == true ? selectedTemplateId : null,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Select a recent meal',
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
                      AppDateUtils.formatDate(AppDateUtils.intToDate(meal.date)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
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
              'No recent workouts',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
          
          return FutureBuilder<List<WorkoutTemplateData>>(
            future: ref.read(databaseProvider).getAllWorkoutTemplates(),
            builder: (context, templateSnapshot) {
              final templates = templateSnapshot.data ?? [];
              
              return DropdownButtonFormField<String>(
                value: selectedTemplateId,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Select a recent workout',
                ),
                isExpanded: true,
                items: sessions.map((session) {
                  final template = templates.where((t) => t.id == session.templateId).firstOrNull;
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final session = sessions.firstWhere((s) => (s.templateId ?? s.id) == value);
                    final template = templates.where((t) => t.id == session.templateId).firstOrNull;
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
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(AppDateUtils.formatDate(date)),
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
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(time.format(context)),
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
Future<String?> _createDataFromTemplate(
  WidgetRef ref,
  EventType type,
  String templateId,
  DateTime scheduledAt,
  String title,
  String? description,
) async {
  try {
    final database = ref.read(databaseProvider);
    final dateInt = AppDateUtils.dateToInt(scheduledAt);
    
    switch (type) {
      case EventType.meal:
        // Check if this is copying from an existing meal or a template
        if (templateId.startsWith('meal_')) {
          // Copy from existing meal
          final existingMealId = templateId.replaceFirst('meal_', '');
          final existingMeal = await ref.read(mealsRepositoryProvider).getMealById(existingMealId);
          
          if (existingMeal != null) {
            final newMeal = meal_models.Meal.create(
              date: dateInt,
              name: title,
              note: description ?? existingMeal.note,
            );
            
            // Copy items from existing meal
            final items = existingMeal.items.map((item) => meal_models.MealItem(
              id: const Uuid().v4(),
              mealId: newMeal.id,
              foodId: item.foodId,
              amount: item.amount,
              kcal: item.kcal,
              protein: item.protein,
              carbs: item.carbs,
              fat: item.fat,
            )).toList();
            
            final mealWithItems = newMeal.copyWith(items: items);
            await ref.read(mealsRepositoryProvider).createMeal(mealWithItems);
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
          final templateItems = await database.getMealTemplateItemsByTemplateId(templateId);
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
          await ref.read(mealsRepositoryProvider).createMeal(mealWithItems);
          return meal.id;
        }
        break;
        
      case EventType.workout:
        // Create workout session from template
        final session = workout_models.WorkoutSession.create(
          templateId: templateId,
          note: description,
        );
        
        await ref.read(workoutSessionsRepositoryProvider).createSession(session);
        return session.id;
        
      case EventType.sleep:
        // Create sleep entry
        final sleep = sleep_models.SleepEntry.create(
          startedAt: scheduledAt,
          note: description,
        );
        
        await ref.read(sleepRepositoryProvider).createEntry(sleep);
        return sleep.id;
    }
  } catch (e) {
    debugPrint('Error creating data from template: $e');
    return null;
  }
  return null;
}

