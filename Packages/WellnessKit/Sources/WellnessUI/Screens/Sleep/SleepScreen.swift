import SwiftUI
import WellnessModels
import WellnessStores

public struct SleepScreen: View {
    @Environment(SleepFeatureStore.self) private var sleepStore

    @State private var showAddSheet = false
    @State private var editingEntry: SleepEntry?

    public init() {}

    public var body: some View {
        List {
            Section {
                SleepSummaryCard(
                    lastNight: sleepStore.lastNightHours,
                    weekAvg: sleepStore.weekAvgHours
                )
            }

            Section {
                if let active = sleepStore.activeSleep {
                    ActiveSleepRow(entry: active) {
                        Task { try? await sleepStore.stopSleep(active.id) }
                    }
                } else {
                    Button {
                        Task { _ = try? await sleepStore.startSleep() }
                    } label: {
                        Label("Start Sleep Timer", systemImage: "moon.zzz.fill")
                    }
                }
            }

            Section("Recent") {
                if sleepStore.recentEntries.filter({ $0.endedAt != nil }).isEmpty {
                    ContentUnavailableView(
                        "No Sleep Data",
                        systemImage: "moon.zzz",
                        description: Text("Track your sleep to see history here.")
                    )
                } else {
                    ForEach(sleepStore.recentEntries.filter({ $0.endedAt != nil }).prefix(14)) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            SleepEntryRow(entry: entry)
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { try? await sleepStore.deleteSleep(id: entry.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sleep")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                AddSleepSheet()
            }
        }
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                AddSleepSheet(entry: entry)
            }
        }
        .refreshable { await sleepStore.load() }
    }
}

struct SleepSummaryCard: View {
    let lastNight: Double?
    let weekAvg: Double?

    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .foregroundStyle(.indigo)
                Text(lastNight.map { String(format: "%.1fh", $0) } ?? "—")
                    .font(.title2.bold())
                Text("Last Night")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.indigo)
                Text(weekAvg.map { String(format: "%.1fh", $0) } ?? "—")
                    .font(.title2.bold())
                Text("7-Night Avg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }
}

struct ActiveSleepRow: View {
    let entry: SleepEntry
    let onStop: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Sleeping...")
                    .font(.headline)
                Text("Since \(entry.startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Stop", action: onStop)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct SleepEntryRow: View {
    let entry: SleepEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.startedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                if let hours = entry.durationInHours {
                    Text(String(format: "%.1fh", hours))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let quality = entry.quality {
                StarRating(value: quality)
            }
        }
    }
}

struct StarRating: View {
    let value: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= value ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(star <= value ? .yellow : .secondary.opacity(0.3))
            }
        }
    }
}
