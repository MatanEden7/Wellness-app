import SwiftUI

public struct BackupSettingsScreen: View {
    @State private var showExportConfirm = false
    @State private var showImportPicker = false
    @State private var showDeleteConfirm = false

    public init() {}

    public var body: some View {
        Form {
            Section("Export") {
                Button {
                    showExportConfirm = true
                } label: {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }
            }

            Section("Import") {
                Button {
                    showImportPicker = true
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
            }

            Section("Danger Zone") {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Backup & Restore")
        .alert("Export Data", isPresented: $showExportConfirm) {
            Button("OK") {}
        } message: {
            Text("Data export will be available in a future update.")
        }
        .alert("Import Data", isPresented: $showImportPicker) {
            Button("OK") {}
        } message: {
            Text("Data import will be available in a future update.")
        }
        .confirmationDialog("Delete All Data?", isPresented: $showDeleteConfirm) {
            Button("Delete Everything", role: .destructive) {}
        } message: {
            Text("This will permanently delete all your data. This cannot be undone.")
        }
    }
}
