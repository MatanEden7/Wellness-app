import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum EventType { meal, workout, sleep }
enum RecurrenceType { none, daily, weekly, monthly, custom }
enum EventStatus { planned, completed, missed, active }

class ScheduledEvent {
  final String id;
  final String title;
  final String? description;
  final EventType type;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final EventStatus status;
  final RecurrenceType recurrenceType;
  final List<int> recurrenceDays; // 1-7 for Mon-Sun (for weekly)
  final int? customInterval; // For custom recurrence (e.g., every 3 days)
  final DateTime? recurrenceEndDate;
  final String? templateId; // For workout/meal templates
  final Map<String, dynamic>? metadata; // Additional data

  const ScheduledEvent({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.scheduledAt,
    this.completedAt,
    this.status = EventStatus.planned,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceDays = const [],
    this.customInterval,
    this.recurrenceEndDate,
    this.templateId,
    this.metadata,
  });

  factory ScheduledEvent.create({
    required String title,
    String? description,
    required EventType type,
    required DateTime scheduledAt,
    RecurrenceType recurrenceType = RecurrenceType.none,
    List<int> recurrenceDays = const [],
    int? customInterval,
    DateTime? recurrenceEndDate,
    String? templateId,
    Map<String, dynamic>? metadata,
  }) {
    return ScheduledEvent(
      id: _uuid.v4(),
      title: title,
      description: description,
      type: type,
      scheduledAt: scheduledAt,
      recurrenceType: recurrenceType,
      recurrenceDays: recurrenceDays,
      customInterval: customInterval,
      recurrenceEndDate: recurrenceEndDate,
      templateId: templateId,
      metadata: metadata,
    );
  }

  ScheduledEvent copyWith({
    String? id,
    String? title,
    String? description,
    EventType? type,
    DateTime? scheduledAt,
    DateTime? completedAt,
    EventStatus? status,
    RecurrenceType? recurrenceType,
    List<int>? recurrenceDays,
    int? customInterval,
    DateTime? recurrenceEndDate,
    String? templateId,
    Map<String, dynamic>? metadata,
    // `templateId: null` is indistinguishable from "leave it alone" in the
    // usual copyWith idiom, so unpinning needs its own flag. Used when a
    // regeneration leaves an event pointing at a template that no longer
    // exists and there is nothing generated to re-point it to -- a null
    // templateId has working fallbacks, a dangling one does not.
    bool clearTemplateId = false,
  }) {
    return ScheduledEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      customInterval: customInterval ?? this.customInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      templateId: clearTemplateId ? null : (templateId ?? this.templateId),
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isCompleted => status == EventStatus.completed;
  bool get isPlanned => status == EventStatus.planned;
  bool get isMissed => status == EventStatus.missed;
  bool get isActive => status == EventStatus.active;
  bool get hasRecurrence => recurrenceType != RecurrenceType.none;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'scheduledAt': scheduledAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'recurrenceType': recurrenceType.name,
      'recurrenceDays': recurrenceDays,
      'customInterval': customInterval,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'templateId': templateId,
      'metadata': metadata,
    };
  }

  factory ScheduledEvent.fromJson(Map<String, dynamic> json) {
    return ScheduledEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: EventType.values.firstWhere((e) => e.name == json['type']),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      status: EventStatus.values.firstWhere((e) => e.name == json['status']),
      recurrenceType: RecurrenceType.values.firstWhere((e) => e.name == json['recurrenceType']),
      recurrenceDays: List<int>.from(json['recurrenceDays'] ?? []),
      customInterval: json['customInterval'] as int?,
      recurrenceEndDate: json['recurrenceEndDate'] != null ? DateTime.parse(json['recurrenceEndDate'] as String) : null,
      templateId: json['templateId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class CalendarDay {
  final DateTime date;
  final List<ScheduledEvent> events;
  final bool hasLoggedMeals;
  final bool hasLoggedWorkouts;
  final bool hasLoggedSleep;

  const CalendarDay({
    required this.date,
    this.events = const [],
    this.hasLoggedMeals = false,
    this.hasLoggedWorkouts = false,
    this.hasLoggedSleep = false,
  });

  CalendarDay copyWith({
    DateTime? date,
    List<ScheduledEvent>? events,
    bool? hasLoggedMeals,
    bool? hasLoggedWorkouts,
    bool? hasLoggedSleep,
  }) {
    return CalendarDay(
      date: date ?? this.date,
      events: events ?? this.events,
      hasLoggedMeals: hasLoggedMeals ?? this.hasLoggedMeals,
      hasLoggedWorkouts: hasLoggedWorkouts ?? this.hasLoggedWorkouts,
      hasLoggedSleep: hasLoggedSleep ?? this.hasLoggedSleep,
    );
  }

  List<ScheduledEvent> get plannedEvents => events.where((e) => e.isPlanned).toList();
  List<ScheduledEvent> get completedEvents => events.where((e) => e.isCompleted).toList();
  List<ScheduledEvent> get mealEvents => events.where((e) => e.type == EventType.meal).toList();
  List<ScheduledEvent> get workoutEvents => events.where((e) => e.type == EventType.workout).toList();
  List<ScheduledEvent> get sleepEvents => events.where((e) => e.type == EventType.sleep).toList();

  bool get hasAnyEvents => events.isNotEmpty;
  bool get hasAnyLogged => hasLoggedMeals || hasLoggedWorkouts || hasLoggedSleep;
}

enum CalendarViewMode { month, week, day }

class CalendarState {
  final CalendarViewMode viewMode;
  final DateTime focusedDate;
  final DateTime? selectedDate;
  final Map<DateTime, CalendarDay> days;
  final bool showPlanned;
  final bool showCompleted;
  final List<EventType> visibleTypes;

  const CalendarState({
    this.viewMode = CalendarViewMode.month,
    required this.focusedDate,
    this.selectedDate,
    this.days = const {},
    this.showPlanned = true,
    this.showCompleted = true,
    this.visibleTypes = const [EventType.meal, EventType.workout, EventType.sleep],
  });

  CalendarState copyWith({
    CalendarViewMode? viewMode,
    DateTime? focusedDate,
    DateTime? selectedDate,
    Map<DateTime, CalendarDay>? days,
    bool? showPlanned,
    bool? showCompleted,
    List<EventType>? visibleTypes,
  }) {
    return CalendarState(
      viewMode: viewMode ?? this.viewMode,
      focusedDate: focusedDate ?? this.focusedDate,
      selectedDate: selectedDate ?? this.selectedDate,
      days: days ?? this.days,
      showPlanned: showPlanned ?? this.showPlanned,
      showCompleted: showCompleted ?? this.showCompleted,
      visibleTypes: visibleTypes ?? this.visibleTypes,
    );
  }
}
