import SwiftUI
import Quartz

struct QLImage: NSViewRepresentable {
    private let name: String

    init(_ name: String) {
        self.name = name
    }

    func makeNSView(context: Context) -> QLPreviewView {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif") else {
            print("Cannot get image \(name)")
            return QLPreviewView()
        }
        let preview = QLPreviewView(frame: .zero, style: .normal)
        preview?.autostarts = true
        preview?.previewItem = url as QLPreviewItem
        return preview ?? QLPreviewView()
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif") else { return }
        nsView.previewItem = url as QLPreviewItem
    }

    typealias NSViewType = QLPreviewView
}