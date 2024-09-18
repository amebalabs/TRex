import ArgumentParser
import Foundation
import TRexCore

let _trex = TRex()

struct trex: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Magic OCR for macOS")

    @Flag(name: .shortAndLong, help: "Run automation with extracted text as input. Automations are configured in TRex app")
    var automation = false

    @Flag(name: .shortAndLong, help: "Capture from image in clipboard")
    var clipboard = false

    @Flag(name: .shortAndLong, help: "Read file from standard input")
    var input = false

    func run() throws {
        if clipboard {
            _trex.capture(automation ? .captureClipboardAndTriggerAutomation : .captureClipboard)
            return
        }

        if input, let data = try? FileHandle.standardInput.readToEnd() {
            try? data.write(to: URL(fileURLWithPath: _trex.screenShotFilePath))
            _trex.capture(automation ? .captureFromFileAndTriggerAutomation : .captureFromFile, imagePath: _trex.screenShotFilePath)
            return
        }

        _trex.capture(automation ? .captureScreenAndTriggerAutomation : .captureScreen)
    }
}

trex.main()
