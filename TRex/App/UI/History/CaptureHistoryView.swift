import SwiftUI
import TRexCore

struct CaptureHistoryView: View {
    @ObservedObject var store: CaptureHistoryStore
    @ObservedObject private var preferences = Preferences.shared
    @State private var searchText = ""
    @State private var selectedEntryID: UUID?
    @State private var showClearConfirmation = false

    private var filteredEntries: [CaptureHistoryEntry] {
        if searchText.isEmpty {
            return store.entries
        }
        return store.entries.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HSplitView {
            // List panel
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search captures...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                if filteredEntries.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: searchText.isEmpty ? "clock" : "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "No captures yet" : "No matches")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredEntries, selection: $selectedEntryID) { entry in
                        CaptureHistoryRow(
                            entry: entry,
                            thumbnailURL: store.thumbnailURL(for: entry)
                        )
                        .tag(entry.id)
                    }
                    .listStyle(.sidebar)
                }

                Divider()

                // Sidebar footer controls
                HStack(spacing: 6) {
                    Toggle("Enabled", isOn: $preferences.captureHistoryEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .font(.caption)
                        .help("Enable or disable capture history recording")

                    Text("\(store.entries.count) / \(preferences.captureHistoryMaxEntries)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .help("Current entries / maximum entries")

                    Stepper("", value: $preferences.captureHistoryMaxEntries,
                            in: 10...500, step: 10)
                        .labelsHidden()
                        .controlSize(.mini)
                        .help("Adjust maximum number of history entries")

                    Spacer()

                    Button {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.entries.isEmpty)
                    .help("Clear all history entries and thumbnails")
                    .alert("Clear Capture History?", isPresented: $showClearConfirmation) {
                        Button("Cancel", role: .cancel) {}
                        Button("Clear All", role: .destructive) {
                            store.clearAll()
                            selectedEntryID = nil
                        }
                    } message: {
                        Text("This will permanently delete all capture history entries and thumbnails.")
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .frame(minWidth: 250, idealWidth: 300)

            // Detail panel
            if let selectedID = selectedEntryID,
               let entry = store.entries.first(where: { $0.id == selectedID }) {
                CaptureHistoryDetailView(
                    entry: entry,
                    thumbnailURL: store.thumbnailURL(for: entry),
                    onDelete: {
                        store.removeEntry(entry)
                        selectedEntryID = nil
                    }
                )
                .frame(minWidth: 300)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Select a capture to view details")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minWidth: 300)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
