import SwiftUI
import TRexCore

struct CaptureHistoryDetailView: View {
    let entry: CaptureHistoryEntry
    let thumbnailURL: URL?
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            if let url = thumbnailURL, let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // Metadata
            GroupBox {
                VStack(alignment: .leading, spacing: 4) {
                    metadataRow(label: "Captured", value: entry.timestamp.formatted(date: .abbreviated, time: .standard))

                    if let engineName = entry.engineName {
                        metadataRow(label: "Engine", value: engineName)
                    }

                    if entry.confidence > 0 {
                        metadataRow(label: "Confidence", value: String(format: "%.0f%%", entry.confidence * 100))
                    }

                    if !entry.recognizedLanguages.isEmpty {
                        metadataRow(label: "Languages", value: entry.recognizedLanguages.joined(separator: ", "))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Full text
            ScrollView {
                Text(entry.text)
                    .textSelection(.enabled)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)

            // Actions
            HStack {
                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(entry.text, forType: .string)
                } label: {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                }

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .padding()
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
            Text(value)
                .font(.caption)
        }
    }
}
