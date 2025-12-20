import ArgumentParser
import Foundation
import TRexCore

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
        let trexInstance = TRex()

        if clipboard {
            await trexInstance.capture(automation ? .captureClipboardAndTriggerAutomation : .captureClipboard)
            Darwin.exit(0)
        }

        if input, let data = try? FileHandle.standardInput.readToEnd() {
            try? data.write(to: URL(fileURLWithPath: trexInstance.screenShotFilePath))
            await trexInstance.capture(automation ? .captureFromFileAndTriggerAutomation : .captureFromFile, imagePath: trexInstance.screenShotFilePath)
            Darwin.exit(0)
        }

        await trexInstance.capture(automation ? .captureScreenAndTriggerAutomation : .captureScreen)
        Darwin.exit(0)
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
