import SwiftUI
import WellnessModels
import WellnessStores

public struct CalendarScreen: View {
    @Environment(CalendarFeatureStore.self) private var calendarStore
    @State private var selectedDate = Date()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            DatePicker(
                "Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)

            let dayEvents = calendarStore.eventsForDate(selectedDate)

            List {
                if dayEvents.isEmpty {
                    ContentUnavailableView(
                        "No Events",
                        systemImage: "calendar",
                        description: Text("No events scheduled for this day.")
                    )
                } else {
                    ForEach(dayEvents) { event in
                        EventRow(event: event) {
                            Task { try? await calendarStore.completeEvent(event.id) }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { try? await calendarStore.deleteEvent(id: event.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Calendar")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                NavigationLink(value: AppRoute.calendarSchedule) {
                    Image(systemName: "calendar.badge.plus")
                }
            }
        }
        .refreshable { await calendarStore.load() }
    }
}

struct EventRow: View {
    let event: ScheduledEvent
    let onComplete: () -> Void

    var body: some View {
        HStack {
            eventIcon
                .foregroundStyle(eventColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .strikethrough(event.status == .completed)
                Text(event.scheduledAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if event.status != .completed {
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var eventIcon: Image {
        switch event.type {
        case .meal: Image(systemName: "fork.knife")
        case .workout: Image(systemName: "dumbbell")
        case .sleep: Image(systemName: "moon.zzz")
        }
    }

    private var eventColor: Color {
        switch event.type {
        case .meal: .orange
        case .workout: .blue
        case .sleep: .purple
        }
    }
}
