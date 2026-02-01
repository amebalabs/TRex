# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TRex is a macOS menu bar application that performs OCR (Optical Character Recognition) to extract text from any visible content on screen directly to the clipboard. Built with Swift and SwiftUI, it requires macOS 14.0+ (Sonoma).

## Build Commands

```bash
# Build the main app
xcodebuild -scheme TRex -configuration Release build

# Build the CLI tool
xcodebuild -scheme "TRex CMD" -configuration Release build

# Clean build
xcodebuild -scheme TRex clean

# Build and run (opens in Xcode)
xcodebuild -scheme TRex -configuration Debug build && open build/Debug/TRex.app
```

## Architecture

The codebase follows a modular architecture:

- **TRex/** - Main app target containing UI and app lifecycle management
  - **App/UI/** - SwiftUI views and UI components
  - **App/Utils.swift** - Core utilities and helper functions
  - **AppDelegate.swift** - Handles app lifecycle, menu bar setup, and global shortcuts
  - **TRexApp.swift** - SwiftUI app entry point

- **Packages/TRexCore/** - Core OCR functionality as a Swift Package
  - Contains the text recognition and QR code detection logic
  - Platform requirement: macOS 14.0+

- **Packages/TRexLLM/** - LLM integration for OCR and text post-processing
  - Uses AnyLanguageModel for unified provider support
  - Supports OpenAI, Anthropic, Ollama, and Apple Intelligence
  - Platform requirement: macOS 14.0+

- **TRex CMD/** - Command-line interface implementation

## Key Technologies & Patterns

- **OCR Implementation**: Uses Apple's Vision framework (`VNRecognizeTextRequest`) for text recognition
- **QR/Barcode Detection**: Uses `CIDetector` for QR code and barcode scanning
- **Global Shortcuts**: Implemented via KeyboardShortcuts library by Sindre Sorhus
- **Menu Bar App**: Configured as `LSUIElement` (no dock icon, lives in menu bar)
- **URL Schemes**: Supports automation through custom URL schemes (trex://)
- **Automation**: Integrates with Shortcuts.app and supports custom URL triggers

## Development Guidelines

When modifying TRex:

1. **Swift Version**: Use Swift 6.1+ features and syntax (strict concurrency enabled)
2. **UI Framework**: All UI should be built with SwiftUI
3. **Minimum OS**: Ensure compatibility with macOS 14.0+ (Sonoma). Apple Intelligence features require macOS 15.1+
4. **Dependencies**: Managed via Swift Package Manager (KeyboardShortcuts, LaunchAtLogin, AnyLanguageModel)
5. **Text Recognition**: Vision framework calls should handle multiple recognition levels
6. **Error Handling**: OCR operations should gracefully handle failures and provide user feedback via notifications
7. **Concurrency**: All code must be Swift 6 concurrency-safe (Sendable protocol, actor isolation)

## Testing

The project currently has no test suite. When implementing tests, use XCTest framework following standard Swift testing patterns.

## Distribution

TRex is distributed through:
- Mac App Store
- GitHub Releases (direct download)
- Homebrew (`brew install trex`)

## URL Scheme Support

The app registers and handles these URL schemes:
- `trex://capture` - Trigger screen capture
- `trex://captureclipboard` - Capture from clipboard
- `trex://captureautomation` - Capture and run automation
- `trex://captureclipboardautomation` - Capture clipboard and run automation
- `trex://shortcut?name=` - Set Shortcuts.app shortcut
- `trex://showPreferences` - Open preferences window

## Tesseract OCR Integration

TRex now includes optional Tesseract OCR support for additional languages:

### Building Tesseract
```bash
# Build libraries (requires cmake, already done)
./Scripts/build-tesseract.sh

# Download core language files
./Scripts/download-tessdata.sh
```

### OCR Architecture
- **OCREngine protocol** - Abstraction for OCR engines (Sendable for Swift 6)
- **VisionOCREngine** - Apple Vision framework (default, 14 languages)
- **TesseractOCREngine** - Tesseract OCR (100+ languages, currently stubbed)
- **LLMOCREngine** - LLM-based vision OCR (supports all languages via GPT-4o, Claude, etc.)
- **OCRManager** - Intelligent routing between engines (thread-safe singleton)

### App Store Preparation
Before submitting to App Store, run:
```bash
# In Xcode build phase or manually
./Scripts/app-store-prepare.sh
```

Note: Tesseract integration is currently using a stub implementation. To enable full functionality, build the libraries using the provided scripts.

## LLM Integration

TRex supports LLM-powered OCR and text post-processing using AnyLanguageModel as a unified API:

### Supported Providers
- **OpenAI** - GPT-4o, GPT-4o-mini (vision + text)
- **Anthropic** - Claude Sonnet 4.5, Claude 3.5 Sonnet (vision + text)
- **Ollama** - Local models like llama3.2-vision, qwen3 (vision + text)
- **Apple Intelligence** - SystemLanguageModel (text only, requires macOS 15.1+)

### Features
- **Separate provider selection** - Different providers for OCR vs post-processing
- **Vision capabilities** - LLMs can perform OCR directly on images
- **On-device processing** - Apple Intelligence runs locally without API calls
- **Network connectivity checks** - Automatic fallback to built-in OCR if network unavailable

### Implementation
- **UnifiedLanguageModelProvider** - Wraps AnyLanguageModel for all providers
- **LLMOCREngine** - Implements OCREngine protocol using LLM vision
- **LLMPostProcessor** - Post-processes OCR results with LLMs
- **Per-feature configuration** - Separate API keys/endpoints for OCR and post-processing