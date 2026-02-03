# LLM Integration Design for TRex

## Overview

Adding LLM capabilities to TRex for enhanced OCR quality and post-processing. Two main features:
1. **LLM Post-Processing**: Enhance existing OCR output with error correction and formatting
2. **LLM OCR Engine**: Use vision-capable LLMs directly for text extraction

## Architecture

### 1. New Swift Package: `TRexLLM`

Located at: `Packages/TRexLLM/`

```
TRexLLM/
├── Sources/
│   ├── TRexLLM/
│   │   ├── Providers/
│   │   │   ├── LLMProvider.swift          // Protocol
│   │   │   ├── OpenAIProvider.swift       // GPT-4V, GPT-4o
│   │   │   ├── AnthropicProvider.swift    // Claude with vision
│   │   │   └── OpenAICompatibleProvider.swift // Ollama, LM Studio, etc.
│   │   ├── Engines/
│   │   │   └── LLMOCREngine.swift         // Implements OCREngine
│   │   ├── Processing/
│   │   │   └── LLMPostProcessor.swift     // Post-process OCR text
│   │   ├── Utils/
│   │   │   ├── ImagePreprocessor.swift    // Compress/optimize images
│   │   │   ├── NetworkChecker.swift       // Connectivity check
│   │   │   └── PromptTemplates.swift      // Default prompts
│   │   └── Models/
│   │       ├── LLMConfiguration.swift     // Config models
│   │       └── LLMError.swift             // Error types
```

### 2. Core Protocols

#### LLMProvider Protocol
```swift
protocol LLMProvider {
    var name: String { get }
    var supportedModels: [String] { get }

    // Vision OCR
    func performOCR(
        image: NSImage,
        prompt: String?,
        model: String
    ) async throws -> String

    // Text post-processing
    func processText(
        _ text: String,
        prompt: String,
        model: String
    ) async throws -> String

    // Configuration
    func configure(apiKey: String?, endpoint: String?)
    func checkConnectivity() async -> Bool
}
```

#### LLMOCREngine (implements OCREngine)
```swift
class LLMOCREngine: OCREngine {
    private let provider: LLMProvider
    private let config: LLMConfiguration
    private let imagePreprocessor: ImagePreprocessor
    private let networkChecker: NetworkChecker

    func recognizeText(in image: NSImage) async throws -> String {
        // 1. Check network connectivity
        // 2. Preprocess image (compress, optimize)
        // 3. Call provider.performOCR()
        // 4. Fallback to VisionOCREngine if fails
    }
}
```

#### LLMPostProcessor
```swift
class LLMPostProcessor {
    private let provider: LLMProvider
    private let config: LLMConfiguration

    func process(
        _ text: String,
        prompt: String? = nil
    ) async throws -> String {
        // 1. Check network connectivity
        // 2. Use custom prompt or default template
        // 3. Call provider.processText()
        // 4. Return original text if fails
    }
}
```

### 3. Configuration Model

```swift
struct LLMConfiguration: Codable {
    // Provider settings
    var provider: LLMProviderType // .openai, .anthropic, .custom
    var apiKey: String?
    var customEndpoint: String? // For local/OpenAI-compatible

    // Model selection
    var ocrModel: String
    var postProcessModel: String

    // Feature flags
    var enableLLMOCR: Bool
    var enablePostProcessing: Bool

    // Prompts (user-editable)
    var ocrPrompt: String
    var postProcessPrompt: String

    // Behavior
    var fallbackToBuiltInOCR: Bool
    var showProcessingIndicator: Bool

    // Environment variable keys
    static let openAIKeyEnvVar = "OPENAI_API_KEY"
    static let anthropicKeyEnvVar = "ANTHROPIC_API_KEY"
}

enum LLMProviderType: String, Codable {
    case openai
    case anthropic
    case custom
}
```

### 4. Integration Points

#### OCRManager Changes
```swift
class OCRManager {
    private let visionEngine: VisionOCREngine
    private let tesseractEngine: TesseractOCREngine
    private let llmEngine: LLMOCREngine? // Optional
    private let llmPostProcessor: LLMPostProcessor?

    func performOCR(
        image: NSImage,
        useEngine: OCREngineType
    ) async throws -> String {
        var result: String

        // Select engine
        switch useEngine {
        case .vision:
            result = try await visionEngine.recognizeText(in: image)
        case .tesseract:
            result = try await tesseractEngine.recognizeText(in: image)
        case .llm:
            result = try await llmEngine?.recognizeText(in: image) ?? ""
        }

        // Optional post-processing
        if config.enablePostProcessing && useEngine != .llm {
            result = try await llmPostProcessor?.process(result) ?? result
        }

        return result
    }
}

enum OCREngineType {
    case vision
    case tesseract
    case llm
}
```

#### AppDelegate Changes
```swift
// New keyboard shortcuts
extension AppDelegate {
    func setupKeyboardShortcuts() {
        // Existing shortcuts
        KeyboardShortcuts.onKeyUp(for: .captureText) { ... }

        // New LLM shortcuts
        KeyboardShortcuts.onKeyUp(for: .captureLLM) {
            // Capture with LLM OCR
        }

        KeyboardShortcuts.onKeyUp(for: .captureWithPostProcess) {
            // Capture with Vision + LLM post-processing
        }
    }
}
```

#### New URL Schemes
```
trex://capturellm                    // Capture with LLM OCR
trex://capturepostprocess            // Capture with post-processing
trex://capturellmautomation          // LLM + automation
```

### 5. Preferences UI

New section in Preferences window:

```
┌─────────────────────────────────────┐
│ LLM Integration                     │
├─────────────────────────────────────┤
│                                     │
│ Provider:                           │
│ ○ OpenAI  ○ Anthropic  ○ Custom    │
│                                     │
│ API Key: [________________]         │
│ (or set OPENAI_API_KEY env var)   │
│                                     │
│ Custom Endpoint (if Custom):        │
│ [http://localhost:11434]           │
│                                     │
│ ──────────────────────────────────  │
│                                     │
│ LLM OCR Engine                      │
│ ☑ Enable LLM as OCR option         │
│ Model: [gpt-4o ▼]                  │
│ Prompt: [Extract all text...]       │
│                                     │
│ ──────────────────────────────────  │
│                                     │
│ Post-Processing                     │
│ ☑ Enable post-processing           │
│ Model: [gpt-4o ▼]                  │
│ Prompt: [Correct errors and...]    │
│                                     │
│ ──────────────────────────────────  │
│                                     │
│ Options                             │
│ ☑ Fallback to built-in OCR         │
│ ☑ Show processing indicator        │
└─────────────────────────────────────┘
```

## User Workflows

### Workflow 1: Standard OCR with Post-Processing
1. User presses keyboard shortcut (e.g., Cmd+Shift+2)
2. TRex captures screen area
3. Vision OCR extracts text
4. LLM post-processes text (error correction, formatting)
5. Result goes to clipboard
6. Notification shows success

### Workflow 2: Direct LLM OCR
1. User presses LLM keyboard shortcut (e.g., Cmd+Shift+3)
2. TRex captures screen area
3. Checks network connectivity
4. Preprocesses image (compresses)
5. Sends to LLM vision API
6. Result goes to clipboard
7. If fails: falls back to Vision OCR

### Workflow 3: From Clipboard
1. User copies image to clipboard
2. Presses clipboard capture shortcut
3. Same logic as above applies

## Default Prompts

### OCR Prompt
```
Extract all visible text from this image. Preserve the layout and formatting as much as possible. Return only the extracted text without any additional commentary.
```

### Post-Processing Prompt
```
You are given OCR output that may contain errors. Please:
1. Correct any obvious spelling or recognition errors
2. Fix formatting issues (spacing, line breaks)
3. Preserve the original structure and meaning
4. Return only the corrected text without explanations

OCR Text:
{text}
```

## Image Preprocessing

To minimize transfer time and API costs while maintaining quality:

1. **Resize**: Max dimension 2048px
2. **Compress**: JPEG quality 85%
3. **Format**: Convert to JPEG (smaller than PNG)
4. **Max size**: 2MB target

```swift
class ImagePreprocessor {
    private static let maxDimension: CGFloat = 2048
    private static let jpegQuality: CGFloat = 0.85
    private static let targetMaxSize: Int = 2_097_152 // 2MB

    func preprocess(_ image: NSImage) -> Data {
        // 1. Calculate target dimensions
        // 2. Resize if needed
        // 3. Convert to JPEG with quality 0.85
        // 4. If still > 2MB, reduce quality incrementally
        // 5. Return Data
    }
}
```

## Error Handling

```swift
enum LLMError: Error {
    case networkUnavailable
    case invalidAPIKey
    case providerError(String)
    case imageProcessingFailed
    case responseParsingFailed
    case timeout
}
```

### Fallback Strategy
- Network check before API call
- If LLM fails → fallback to Vision OCR
- Show notification indicating fallback occurred
- Log errors locally (not to network)

## Privacy Considerations

1. **Explicit opt-in**: LLM features disabled by default
2. **Clear warnings**: UI indicates when data leaves device
3. **Local option**: Custom endpoint for local models
4. **No logging**: Images/text not cached or logged
5. **Environment variables**: Support for key management outside app
6. **Secure storage**: API keys in macOS Keychain

## Implementation Phases

### Phase 1: Foundation
- Create TRexLLM package
- Implement LLMProvider protocol
- Implement OpenAIProvider
- Add basic configuration model
- Add image preprocessor

### Phase 2: Core Features
- Implement LLMOCREngine
- Implement LLMPostProcessor
- Integrate with OCRManager
- Add network checker

### Phase 3: UI & Configuration
- Add LLM section to Preferences
- Add keyboard shortcuts
- Add URL schemes
- Add status indicators

### Phase 4: Additional Providers
- Implement AnthropicProvider
- Implement OpenAICompatibleProvider
- Add provider-specific model lists

### Phase 5: Polish
- Add comprehensive error messages
- Add usage tips/documentation
- Test fallback scenarios
- Performance optimization

## Testing Strategy

Since there are no tests currently, we should add:

1. **Unit Tests**
   - Provider API formatting
   - Image preprocessing
   - Prompt template generation
   - Configuration parsing

2. **Integration Tests**
   - Full OCR workflow
   - Post-processing workflow
   - Fallback scenarios
   - Network failure handling

3. **Manual Testing**
   - Real API calls with all providers
   - Various image types and qualities
   - Different network conditions
   - Keyboard shortcut conflicts

## Decisions Made

1. ~~Streaming responses~~ - No, doesn't make UX sense
2. ~~Multiple post-processing steps~~ - Not for initial release
3. ~~Cost estimator~~ - No
4. ~~Default keyboard shortcuts~~ - Users will configure their own
5. ~~Image quality settings~~ - Single good default (2048px, 85% JPEG)
6. ~~Review before clipboard mode~~ - No, keep existing fast workflow

## User Experience Flow

**Standard flow unchanged:**
```
Capture → OCR Engine → [Optional: Post-process] → Clipboard → Notification
```

**With LLM:**
- User selects LLM OCR engine → same flow, just different engine
- User enables post-processing → runs after any OCR engine (Vision/Tesseract/LLM)
- Network check and fallback happen transparently
- Same speed-focused UX as current TRex

## Next Steps

1. Review this design
2. Confirm approach and priorities
3. Start with Phase 1 implementation
4. Iterate based on feedback
