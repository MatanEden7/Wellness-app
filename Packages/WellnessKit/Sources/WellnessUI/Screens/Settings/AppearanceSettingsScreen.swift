import SwiftUI

public struct AppearanceSettingsScreen: View {
    @AppStorage("accentColorHex") private var accentColorHex = "007AFF"

    private let accentOptions: [(String, Color)] = [
        ("007AFF", .blue),
        ("34C759", .green),
        ("FF9500", .orange),
        ("FF2D55", .pink),
        ("AF52DE", .purple),
        ("FF3B30", .red),
        ("5AC8FA", .cyan),
        ("FFD60A", .yellow),
    ]

    public init() {}

    public var body: some View {
        Form {
            Section("Theme") {
                Text("The app follows your system appearance (Light / Dark).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Accent Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(accentOptions, id: \.0) { hex, color in
                        Button {
                            accentColorHex = hex
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if accentColorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.body.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Appearance")
    }
}
