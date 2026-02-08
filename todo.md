# TRex Feature Roadmap

## 1. ~~OCR History / Clipboard Log~~ ✅ Done
- ~~Searchable history of past captures (text + source thumbnail)~~
- ~~Store last N captures with timestamps~~
- ~~Re-copy or search through past results~~
- ~~Persist across app launches~~
- JSON + thumbnails in `~/Library/Application Support/TRex/History/`
- Configurable max entries (1–10,000, default 100) with automatic pruning and bounds clamping
- Dedicated history window (HSplitView: list + detail) via menu bar submenu or `trex://showHistory`
- Menu bar "History" submenu shows last 5 captures for quick copy
- Enable/disable toggle and controls in history window sidebar footer
- CLI excluded from history writes

## 2. Watch Mode / Continuous Capture
- Monitor a screen region, re-capture on content change (pixel diff)
- Use cases: live dashboards, subtitles, changing data
- Output options: append to file, append to clipboard, notification stream

## 3. ~~Multi-Region Capture~~ ✅ Done
- ~~Draw multiple selection boxes in a single capture session~~
- ~~Combine or individually process each region~~
- ~~Useful for tables, forms, scattered UI elements~~
- Loop-based capture: user selects regions one at a time, press Escape to finish
- OCR results combined with double-newline separator, optional LLM post-processing
- Keyboard shortcuts and menu bar item for both clipboard and automation modes
- URL scheme support: `trex://capturemultiregion`, `trex://capturemultiregionautomation`
- Max 50 regions per session to prevent unbounded memory growth

## 4. ~~Table / Structured Data Mode~~ ✅ Done
- ~~Use Apple Vision `RecognizeDocumentsRequest` (macOS 26+, WWDC25) for native table detection~~
- ~~Returns `DocumentObservation` with hierarchical structure (rows, columns, cells)~~
- ~~Output as CSV, TSV, or Markdown table~~
- ~~Fallback: LLM post-processor with table-extraction prompt for macOS < 26~~
- Ref: https://developer.apple.com/videos/play/wwdc2025/272/
- Enabled by default; toggle + output format selectable from menu bar submenu (Markdown, CSV, TSV, JSON)
- Toggle and format picker also available in General Settings
- Bounding-box filtering separates table text from surrounding paragraphs
- LLM post-processing runs after table detection when both are enabled

## 5. Translation on Capture
- Optionally translate OCR'd text before copying to clipboard
- Apple Translation framework (macOS 15+) for on-device translation
- LLM providers as alternative translation backend
- Settings: toggle + target language selector
