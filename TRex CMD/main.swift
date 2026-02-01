import ArgumentParser
import Foundation
import TRexCore

/// Errors that can occur during CLI execution
enum CLIError: LocalizedError {
    case stdinReadFailed
    case stdinEmpty
    case tempFileWriteFailed(String)

    var errorDescription: String? {
        switch self {
        case .stdinReadFailed:
            return "Failed to read from standard input"
        case .stdinEmpty:
            return "No data received from standard input"
        case .tempFileWriteFailed(let path):
            return "Failed to write temporary file at \(path)"
        }
    }
}

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

        let mode: InvocationMode
        var imagePath: String?

        if clipboard {
            mode = automation ? .captureClipboardAndTriggerAutomation : .captureClipboard
        } else if input {
            guard let data = try? FileHandle.standardInput.readToEnd() else {
                throw CLIError.stdinReadFailed
            }
            guard !data.isEmpty else {
                throw CLIError.stdinEmpty
            }
            let tempPath = trexInstance.screenShotFilePath
            do {
                try data.write(to: URL(fileURLWithPath: tempPath))
            } catch {
                throw CLIError.tempFileWriteFailed(tempPath)
            }
            mode = automation ? .captureFromFileAndTriggerAutomation : .captureFromFile
            imagePath = tempPath
        } else {
            mode = automation ? .captureScreenAndTriggerAutomation : .captureScreen
        }

        await trexInstance.capture(mode, imagePath: imagePath)
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
