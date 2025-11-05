import ArgumentParser
import Foundation
import TRexCore

let _trex = TRex()

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct trex: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Magic OCR for macOS")

    @Flag(name: .shortAndLong, help: "Run automation with extracted text as input. Automations are configured in TRex app")
    var automation = false

    @Flag(name: .shortAndLong, help: "Capture from image in clipboard")
    var clipboard = false

    @Flag(name: .shortAndLong, help: "Read file from standard input")
    var input = false

    func run() async throws {
        if clipboard {
            await _trex.capture(automation ? .captureClipboardAndTriggerAutomation : .captureClipboard)
            return
        }

        if input, let data = try? FileHandle.standardInput.readToEnd() {
            try? data.write(to: URL(fileURLWithPath: _trex.screenShotFilePath))
            await _trex.capture(automation ? .captureFromFileAndTriggerAutomation : .captureFromFile, imagePath: _trex.screenShotFilePath)
            return
        }

        await _trex.capture(automation ? .captureScreenAndTriggerAutomation : .captureScreen)
    }
}

if #available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *) {
    Task {
        await trex.main()
    }
    dispatchMain()
} else {
    fatalError("This tool requires macOS 10.15 or later")
}
