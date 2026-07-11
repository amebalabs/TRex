import AppKit
import AnyLanguageModel
import XCTest

@testable import TRexLLM

final class UnifiedLanguageModelProviderTests: XCTestCase {
    func testPrepareOCRRequestUsesDefaultPromptAndJPEG() throws {
        let request = try UnifiedLanguageModelProvider.prepareOCRRequest(
            image: makeTestImage(),
            prompt: nil
        )

        XCTAssertEqual(request.prompt, PromptTemplates.defaultOCRPrompt)
        XCTAssertEqual(request.mimeType, "image/jpeg")
        XCTAssertEqual(Array(request.imageData.prefix(3)), [0xFF, 0xD8, 0xFF])
    }

    func testPrepareOCRRequestUsesCustomPrompt() throws {
        let request = try UnifiedLanguageModelProvider.prepareOCRRequest(
            image: makeTestImage(),
            prompt: "  Read the vertical Japanese text.  "
        )

        XCTAssertEqual(request.prompt, "Read the vertical Japanese text.")
    }

    func testPrepareOCRRequestUsesDefaultForBlankPrompt() throws {
        let request = try UnifiedLanguageModelProvider.prepareOCRRequest(
            image: makeTestImage(),
            prompt: " \n "
        )

        XCTAssertEqual(request.prompt, PromptTemplates.defaultOCRPrompt)
    }

    func testPerformOCRUsesFreshSessionForEachCapture() async throws {
        let recorder = TranscriptRecorder()
        let provider = UnifiedLanguageModelProvider(model: RecordingLanguageModel(recorder: recorder))

        _ = try await provider.performOCR(image: makeTestImage(), prompt: nil, model: "test")
        _ = try await provider.performOCR(image: makeTestImage(), prompt: nil, model: "test")

        let summaries = await recorder.summaries
        XCTAssertEqual(summaries.map(\.entryCount), [1, 1])
        XCTAssertEqual(summaries.map(\.imageCount), [1, 1])
    }

    private func makeTestImage() -> NSImage {
        let size = NSSize(width: 120, height: 80)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }
}

private actor TranscriptRecorder {
    struct Summary: Sendable {
        let entryCount: Int
        let imageCount: Int
    }

    private(set) var summaries: [Summary] = []

    func record(_ transcript: Transcript) {
        let imageCount = transcript.reduce(into: 0) { count, entry in
            guard case .prompt(let prompt) = entry else { return }
            count += prompt.segments.filter {
                if case .image = $0 { return true }
                return false
            }.count
        }
        summaries.append(Summary(entryCount: transcript.count, imageCount: imageCount))
    }
}

private struct RecordingLanguageModel: LanguageModel {
    typealias UnavailableReason = Never

    let recorder: TranscriptRecorder

    func respond<Content>(
        within session: LanguageModelSession,
        to prompt: Prompt,
        generating type: Content.Type,
        includeSchemaInPrompt: Bool,
        options: GenerationOptions
    ) async throws -> LanguageModelSession.Response<Content> where Content: Generable {
        await recorder.record(session.transcript)
        let content = "recognized text"
        return LanguageModelSession.Response(
            content: content as! Content,
            rawContent: GeneratedContent(content),
            transcriptEntries: []
        )
    }

    func streamResponse<Content>(
        within session: LanguageModelSession,
        to prompt: Prompt,
        generating type: Content.Type,
        includeSchemaInPrompt: Bool,
        options: GenerationOptions
    ) -> sending LanguageModelSession.ResponseStream<Content> where Content: Generable {
        fatalError("Streaming is not used by OCR tests")
    }
}
