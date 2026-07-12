import CoreGraphics
import Foundation
import Vision
import XCTest

@testable import TRexCore

final class TesseractConcurrencyTests: XCTestCase {
    func testCancelledWaiterNeverTouchesNativeEngine() async throws {
        let firstRecognitionStarted = expectation(description: "first recognition started")
        let releaseFirstRecognition = DispatchSemaphore(value: 0)
        let engine = BlockingTesseractEngine(
            onFirstRecognition: { firstRecognitionStarted.fulfill() },
            releaseFirstRecognition: releaseFirstRecognition
        )
        let coordinator = TesseractEngineCoordinator(engine: engine)
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        let image = try XCTUnwrap(context.makeImage())

        let first = Task {
            try await coordinator.recognize(
                image: image,
                language: "eng",
                recognitionLevel: .accurate
            )
        }
        await fulfillment(of: [firstRecognitionStarted], timeout: 1)

        let cancelledWaiter = Task {
            try await coordinator.recognize(
                image: image,
                language: "ita",
                recognitionLevel: .accurate
            )
        }
        cancelledWaiter.cancel()
        releaseFirstRecognition.signal()

        _ = try await first.value

        do {
            _ = try await cancelledWaiter.value
            XCTFail("Expected queued recognition to be cancelled")
        } catch is CancellationError {
            XCTAssertEqual(engine.initializedLanguages, ["eng"])
        }
    }
}

private final class BlockingTesseractEngine: TesseractEngineAdapter, @unchecked Sendable {
    private let lock = NSLock()
    private let onFirstRecognition: @Sendable () -> Void
    private let releaseFirstRecognition: DispatchSemaphore
    private var languages: [String] = []
    private var recognitionCount = 0

    init(
        onFirstRecognition: @escaping @Sendable () -> Void,
        releaseFirstRecognition: DispatchSemaphore
    ) {
        self.onFirstRecognition = onFirstRecognition
        self.releaseFirstRecognition = releaseFirstRecognition
    }

    var initializedLanguages: [String] {
        lock.withLock { languages }
    }

    func initialize(language: String) {
        lock.withLock { languages.append(language) }
    }

    func recognize(
        image: CGImage,
        recognitionLevel: VNRequestTextRecognitionLevel
    ) throws -> (text: String, confidence: Float) {
        let isFirst = lock.withLock { () -> Bool in
            recognitionCount += 1
            return recognitionCount == 1
        }
        if isFirst {
            onFirstRecognition()
            releaseFirstRecognition.wait()
        }
        return ("ok", 1)
    }

    func clear() {}
}
