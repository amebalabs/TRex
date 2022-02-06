import ArgumentParser
import Foundation

let trex = TRex()

struct TRexCMD: ParsableCommand {
    mutating func run() throws {
        trex.capture(.captureScreen)
    }
}

TRexCMD.main()
