import ArgumentParser
import Foundation

let _trex = TRex()

struct trex: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Magic OCR for macOS")

    @Flag(name: .shortAndLong, help: "Run automation with extracted text as input. Automations are configured in TRex app")
    var automation = false

    @Flag(name: .shortAndLong, help: "Capture from image in clipboard")
    var clipboard = false

    @Option(name: .shortAndLong, help: "Input image path")
    var imagePath: String?

    func run() throws {
        if clipboard {
            _trex.capture(automation ? .captureClipboardAndTriggerAutomation : .captureClipboard)
            return
        }

        if !(imagePath?.isEmpty ?? true) {
            _trex.capture(automation ? .captureFromFileAndTriggerAutomation : .captureFromFile, imagePath: imagePath)
            return
        }

        _trex.capture(automation ? .captureScreenAndTriggerAutomation : .captureScreen)
    }
}

trex.main()
