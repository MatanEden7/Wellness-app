import SwiftUI
import WellnessModels
import WellnessStores

public struct SleepScreen: View {
    @Environment(SleepFeatureStore.self) private var sleepStore

    public init() {}

    public var body: some View {
        List {
            Section {
                if let active = sleepStore.activeSleep {
                    ActiveSleepRow(entry: active) {
                        Task { try? await sleepStore.stopSleep(active.id) }
                    }
                } else {
                    Button {
                        Task { _ = try? await sleepStore.startSleep() }
                    } label: {
                        Label("Start Sleep", systemImage: "moon.zzz.fill")
                    }
                }
            }

            Section("Recent") {
                if sleepStore.recentEntries.isEmpty {
                    ContentUnavailableView(
                        "No Sleep Data",
                        systemImage: "moon.zzz",
                        description: Text("Track your sleep to see history here.")
                    )
                } else {
                    ForEach(sleepStore.recentEntries.filter({ $0.endedAt != nil }).prefix(14)) { entry in
                        SleepEntryRow(entry: entry)
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
        .refreshable { await sleepStore.load() }
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
                if let ended = entry.endedAt {
                    let hours = ended.timeIntervalSince(entry.startedAt) / 3600
                    Text(String(format: "%.1fh", hours))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let quality = entry.quality {
                QualityBadge(quality: quality)
            }
        }
    }
}

struct QualityBadge: View {
    let quality: Int

    var body: some View {
        Text("\(quality)/5")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(qualityColor.opacity(0.15))
            .foregroundStyle(qualityColor)
            .clipShape(Capsule())
    }

    private var qualityColor: Color {
        switch quality {
        case 1...2: .red
        case 3: .orange
        case 4...5: .green
        default: .gray
        }
    }
}
