import SwiftUI
import TRexCore

struct CaptureHistoryRow: View {
    let entry: CaptureHistoryEntry
    let thumbnailURL: URL?

    var body: some View {
        HStack(spacing: 8) {
            thumbnailView
                .frame(width: 40, height: 40)
                .cornerRadius(4)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text.components(separatedBy: .newlines).first ?? "")
                    .lineLimit(1)
                    .font(.body)

                HStack(spacing: 4) {
                    Text(entry.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let engineName = entry.engineName {
                        Text("·")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(engineName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let url = thumbnailURL, let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipped()
        } else {
            Image(systemName: "doc.text")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 40, height: 40)
                .background(Color(NSColor.controlBackgroundColor))
        }
    }
}
