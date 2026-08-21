import SwiftUI

public struct AboutScreen: View {
    public init() {}

    public var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.pink)
                        Text("WellnessX")
                            .font(.title.bold())
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            }

            Section {
                LabeledContent("Build", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—")
                LabeledContent("iOS Requirement", value: "18.0+")
            }

            Section {
                Text("Your all-in-one wellness companion for nutrition, workouts, sleep, and more.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
    }
}
