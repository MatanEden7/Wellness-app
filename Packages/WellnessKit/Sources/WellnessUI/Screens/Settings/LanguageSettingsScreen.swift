import SwiftUI
import WellnessModels

public struct LanguageSettingsScreen: View {
    @AppStorage("content_language") private var contentLanguage = "en"

    public init() {}

    public var body: some View {
        Form {
            Section("Content Language") {
                Picker("Language", selection: $contentLanguage) {
                    Text("English").tag("en")
                    Text("עברית (Hebrew)").tag("he")
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section {
                Text("This controls the language for generated content (workout and meal templates). The app interface follows your device language.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Language")
    }
}
