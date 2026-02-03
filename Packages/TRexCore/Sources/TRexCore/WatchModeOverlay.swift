import Cocoa
import Combine
import SwiftUI

/// Displays a visible border around the watched region and a floating control panel.
/// In setup mode: shows Start, Re-select, Cancel, and frequency slider.
/// In capturing mode: shows capture count and Stop button.
@MainActor
final class WatchModeOverlay {

    private var borderWindow: NSWindow?
    private var controlWindow: NSWindow?

    /// Show the overlay for the given screen rect (CGWindow coordinates: origin top-left of main display).
    func show(rect: CGRect, manager: WatchModeManager) {
        hide()

        let screenRect = cgWindowRectToScreen(rect)

        // Border window: click-through, draws only a colored dashed border
        let borderInset: CGFloat = 2
        let borderFrame = screenRect.insetBy(dx: -borderInset, dy: -borderInset)
        let border = NSWindow(
            contentRect: borderFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        border.level = .floating
        border.isOpaque = false
        border.hasShadow = false
        border.backgroundColor = .clear
        border.ignoresMouseEvents = true
        border.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let borderView = BorderView(frame: NSRect(origin: .zero, size: borderFrame.size))
        border.contentView = borderView
        border.orderFrontRegardless()
        borderWindow = border

        // Control panel: centered horizontally on the selection, above it
        let controlWidth: CGFloat = 320
        let controlHeight: CGFloat = 100
        let controlX = screenRect.midX - controlWidth / 2
        // Place above the selection, or below if too close to screen top
        var controlY = screenRect.maxY + 8
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(NSPoint(x: screenRect.midX, y: screenRect.midY)) }) {
            if controlY + controlHeight > screen.frame.maxY {
                controlY = screenRect.minY - controlHeight - 8
            }
        }

        let controlFrame = NSRect(x: controlX, y: controlY, width: controlWidth, height: controlHeight)
        let control = NSPanel(
            contentRect: controlFrame,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        control.level = .floating
        control.isOpaque = false
        control.hasShadow = true
        control.backgroundColor = .clear
        control.titlebarAppearsTransparent = true
        control.titleVisibility = .hidden
        control.isMovableByWindowBackground = true
        control.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let controlView = NSHostingView(rootView: WatchModeControlView(manager: manager))
        control.contentView = controlView
        control.orderFrontRegardless()
        controlWindow = control
    }

    /// Remove all overlay windows.
    func hide() {
        borderWindow?.orderOut(nil)
        borderWindow = nil
        controlWindow?.orderOut(nil)
        controlWindow = nil
    }

    /// Convert a CGWindow rect (origin top-left of main display) to NSScreen coordinates
    /// (origin bottom-left of main display).
    private func cgWindowRectToScreen(_ rect: CGRect) -> NSRect {
        let mainScreenHeight = NSScreen.screens.first?.frame.height ?? rect.origin.y + rect.height
        return NSRect(
            x: rect.origin.x,
            y: mainScreenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}

// MARK: - Border View

/// Draws a colored dashed border, fully transparent interior.
private class BorderView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        let inset: CGFloat = 1
        let borderRect = bounds.insetBy(dx: inset, dy: inset)
        let path = NSBezierPath(rect: borderRect)
        path.lineWidth = 2

        let dashPattern: [CGFloat] = [6, 4]
        path.setLineDash(dashPattern, count: dashPattern.count, phase: 0)

        NSColor.systemBlue.withAlphaComponent(0.8).setStroke()
        path.stroke()
    }
}

// MARK: - Floating Control View

private struct WatchModeControlView: View {
    @ObservedObject var manager: WatchModeManager

    var body: some View {
        VStack(spacing: 8) {
            if manager.isCapturing {
                capturingView
            } else {
                setupView
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var setupView: some View {
        VStack(spacing: 8) {
            // Frequency slider
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Slider(
                    value: Binding(
                        get: { manager.pollingInterval },
                        set: { manager.pollingInterval = $0 }
                    ),
                    in: Preferences.watchModePollingIntervalMin...Preferences.watchModePollingIntervalMax,
                    step: 0.1
                )
                Text(String(format: "%.1fs", manager.pollingInterval))
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 34, alignment: .trailing)
            }

            // Action buttons
            HStack(spacing: 6) {
                Button(action: { manager.beginCapture() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                        Text("Start")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(action: {
                    Task { await manager.reselectRegion() }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "crop")
                            .font(.system(size: 9))
                        Text("Re-select")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(action: { manager.cancel() }) {
                    Text("Cancel")
                        .font(.system(size: 11, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private var capturingView: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            Text("\(manager.captureCount) captures")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)

            Spacer()

            Button(action: { manager.stopWatching() }) {
                HStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 9))
                    Text("Stop")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}
