import SwiftUI
import WellnessModels
import WellnessStores

struct AddSleepSheet: View {
    @Environment(SleepFeatureStore.self) private var sleepStore
    @Environment(\.dismiss) private var dismiss

    let existingEntry: SleepEntry?

    @State private var bedtime: Date = Calendar.current.date(
        bySettingHour: 23, minute: 0, second: 0, of: .now
    ) ?? .now
    @State private var wakeTime: Date = Calendar.current.date(
        bySettingHour: 7, minute: 0, second: 0, of: .now
    ) ?? .now
    @State private var quality: Int = 3
    @State private var note = ""
    @State private var isSaving = false

    private var isNew: Bool { existingEntry == nil }

    init(entry: SleepEntry? = nil) {
        self.existingEntry = entry
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Bedtime", selection: $bedtime)
                DatePicker("Wake Time", selection: $wakeTime)
            }

            Section("Duration") {
                let hours = wakeTime.timeIntervalSince(bedtime) / 3600
                Text(String(format: "%.1f hours", max(0, hours)))
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
            }

            Section("Quality") {
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            quality = star
                        } label: {
                            Image(systemName: star <= quality ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(star <= quality ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }

            Section {
                TextField("Notes (optional)", text: $note, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle(isNew ? "Log Sleep" : "Edit Sleep")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(isSaving || wakeTime <= bedtime)
            }
        }
        .onAppear {
            if let e = existingEntry {
                bedtime = e.startedAt
                wakeTime = e.endedAt ?? .now
                quality = e.quality ?? 3
                note = e.note ?? ""
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let entry = SleepEntry(
            id: existingEntry?.id ?? UUID().uuidString,
            startedAt: bedtime,
            endedAt: wakeTime,
            quality: quality,
            note: note.isEmpty ? nil : note
        )
        if isNew {
            try? await sleepStore.insertSleep(entry)
        } else {
            try? await sleepStore.updateSleep(entry)
        }
        dismiss()
    }
}
