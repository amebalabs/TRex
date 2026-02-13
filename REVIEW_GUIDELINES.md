# Review Guidelines

Project-specific criteria for code reviews in TRex.

## Swift 6 Concurrency

- All types crossing module boundaries must be `Sendable`
- `@MainActor` isolation must be correct — no accessing `@MainActor` properties from nonisolated contexts
- No `@ObservableObject` publisher access (`$property`) from nonisolated contexts
- Prefer structured concurrency (async/await) over callbacks
- Check for data races in shared mutable state

## OCR Engine Protocol

- All OCR engines must conform to `OCREngine` protocol
- Engine implementations must be `Sendable`
- OCR operations must handle failures gracefully with user notifications
- Vision framework calls should support multiple recognition levels

## Code Path Coverage

- When logic is moved or refactored, verify ALL code paths are updated:
  - Primary capture path
  - Clipboard capture path
  - Watch mode capture path
  - Table/structured data detection fallback
  - LLM post-processing path
- Missing a code path during refactoring is a blocking issue

## API & Module Boundaries

- Public API of TRexCore and TRexLLM packages must use `public` access control
- Do not expose internal implementation details across package boundaries
- Check that new public types/methods are intentional

## macOS Compatibility

- All features must work on macOS 14.0+ (Sonoma)
- Apple Intelligence features must be gated behind macOS 15.1+ availability checks
- Menu bar app behavior: no dock icon, proper `LSUIElement` handling
