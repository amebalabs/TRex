import ArgumentParser
import Foundation

let trex = TRex()

struct TRexCMD: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Run Automation")
    var automation = false

    @Flag(name: .shortAndLong, help: "Capture from Clipboard")
    var clipboard = false

    mutating func run() throws {
        if clipboard {
            trex.capture(automation ? .captureClipboardAndTriggerAutomation : .captureClipboard)
            return
        }
        trex.capture(automation ? .captureScreenAndTriggerAutomation : .captureScreen)
    }
}

TRexCMD.main()
