import ArgumentParser
import Foundation

let trex = TRex()

struct TRexCMD: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Run Automation")
    var automation = false

    mutating func run() throws {
        trex.capture(automation ? .captureScreenAndTriggerAutomation : .captureScreen)
    }
}

TRexCMD.main()
