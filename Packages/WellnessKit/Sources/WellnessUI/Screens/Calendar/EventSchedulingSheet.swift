import SwiftUI
import WellnessModels
import WellnessStores

struct EventSchedulingSheet: View {
    @Environment(CalendarFeatureStore.self) private var calendarStore
    @Environment(\.dismiss) private var dismiss

    let existingEvent: ScheduledEvent?
    let preselectedDate: Date

    @State private var title = ""
    @State private var type: EventType = .workout
    @State private var scheduledAt: Date = .now
    @State private var recurrenceType: RecurrenceType = .none
    @State private var recurrenceDays: Set<Int> = []
    @State private var notes = ""
    @State private var isSaving = false

    private var isNew: Bool { existingEvent == nil }

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    init(event: ScheduledEvent? = nil, date: Date = .now) {
        self.existingEvent = event
        self.preselectedDate = date
    }

    var body: some View {
        Form {
            Section {
                TextField("Event Title", text: $title)
                Picker("Type", selection: $type) {
                    Label("Workout", systemImage: "dumbbell").tag(EventType.workout)
                    Label("Meal", systemImage: "fork.knife").tag(EventType.meal)
                    Label("Sleep", systemImage: "moon.zzz").tag(EventType.sleep)
                }
            }

            Section {
                DatePicker("Date & Time", selection: $scheduledAt)
            }

            Section("Recurrence") {
                Picker("Repeat", selection: $recurrenceType) {
                    Text("None").tag(RecurrenceType.none)
                    Text("Daily").tag(RecurrenceType.daily)
                    Text("Weekly").tag(RecurrenceType.weekly)
                    Text("Monthly").tag(RecurrenceType.monthly)
                }

                if recurrenceType == .weekly {
                    HStack(spacing: 6) {
                        ForEach(0..<7) { day in
                            Button {
                                if recurrenceDays.contains(day) {
                                    recurrenceDays.remove(day)
                                } else {
                                    recurrenceDays.insert(day)
                                }
                            } label: {
                                Text(dayNames[day])
                                    .font(.caption2)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        recurrenceDays.contains(day)
                                        ? Color.accentColor : Color.secondary.opacity(0.2)
                                    )
                                    .foregroundStyle(recurrenceDays.contains(day) ? .white : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Section {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            if let existing = existingEvent {
                Section {
                    Button("Delete Event", role: .destructive) {
                        Task {
                            try? await calendarStore.deleteEvent(id: existing.id)
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationTitle(isNew ? "New Event" : "Edit Event")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(title.isEmpty || isSaving)
            }
        }
        .onAppear {
            if let e = existingEvent {
                title = e.title
                type = e.type
                scheduledAt = e.scheduledAt
                recurrenceType = e.recurrenceType
                recurrenceDays = Set(e.recurrenceDays)
                notes = e.description ?? ""
            } else {
                scheduledAt = preselectedDate
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let event = ScheduledEvent(
            id: existingEvent?.id ?? UUID().uuidString,
            title: title,
            description: notes.isEmpty ? nil : notes,
            type: type,
            scheduledAt: scheduledAt,
            status: existingEvent?.status ?? .planned,
            recurrenceType: recurrenceType,
            recurrenceDays: Array(recurrenceDays).sorted()
        )
        if isNew {
            try? await calendarStore.addEvent(event)
        } else {
            try? await calendarStore.updateEvent(event)
        }
        dismiss()
    }
}
