# v2.0.0 (2026-02-13)

# TRex v2.0.0 Release Notes

## ✨ New Features

### Table Detection
- **Vision-based detection**: Uses macOS 26+ document recognition for table extraction
- **LLM fallback**: Falls back to AI-based table detection on older systems
- **Multiple formats**: Export tables as Markdown, CSV, or plain text
- **Menu bar toggle**: Quick access to table detection settings

### LLM Integration
- **AI-powered OCR**: Use OpenAI, Anthropic, Ollama, or Apple Intelligence for vision-based text recognition
- **Smart post-processing**: Automatically format, correct, or transform captured text with LLM
- **Separate provider configuration**: Choose different providers for OCR vs post-processing
- **On-device processing**: Apple Intelligence runs locally with no API calls (macOS 15.1+)
- **Network-aware fallback**: Automatically falls back to built-in OCR when offline

### Multi-Region Capture
- **Batch selection**: Select multiple screen regions in a single capture session
- **Combined results**: OCR results from all regions are merged together
- **Optional LLM processing**: Post-process combined text with AI
- **Up to 50 regions**: Capture complex layouts in one go

### Watch Mode
- **Continuous monitoring**: Monitor a screen region and automatically capture when content changes
- **Interactive region selection**: Draw regions with a visual overlay
- **Floating control panel**: Start, pause, and reselect regions on the fly
- **Multiple output modes**: Append to clipboard, write to file, or stream notifications
- **Smart detection**: SHA256-based change detection with configurable polling interval
- **URL scheme support**: Trigger watch mode via `trex://watch`

### Capture History
- **Persistent history**: All OCR captures saved with thumbnails
- **Quick access**: Last 5 captures available in menu bar submenu
- **History window**: Browse all captures via `trex://showHistory`
- **Configurable storage**: Set max entries (1–10,000)
- **One-click copy**: Quickly copy any previous capture to clipboard


## 🐛 Bug Fixes

### CLI Improvements
- Fixed CLI not exiting after stdin EOF (#61)
- Added back Intel Support
- Improved temp file handling with UUID-based paths

### Language Recognition
- Added Turkish (tr-TR) to Vision OCR fallback language sets (#62)
- Fixed language code normalization to handle underscore format (#65)

### UI Fixes
- Fixed Quick Setup content overflow with scrollable language grid (#63)
- Added confirmation dialog when hiding menu bar icon with recovery instructions (#60)

## 🔗 Links

- [Full Changelog](https://github.com/amebalabs/TRex/compare/v1.9.1...v2.0.0)
- [GitHub Release](https://github.com/amebalabs/TRex/releases/tag/v2.0.0)

# v1.9.1 (2025-11-05)

# TRex v1.9.1 Release Notes

## ✨ New Features

### Command Line Tool
- **In-app CLI installer**: Added one-click installation of the TRex command-line tool directly from the app's preferences window
- **User-local installation**: Installs to `~/.local/bin/trex` with no admin privileges required

## 🐛 Bug Fixes

### Language Recognition
- **Fixed language code normalization**: Resolved issues with Czech (and potentially other) language recognition where language codes with underscores (`cs_CZ`) weren't being properly converted to the hyphen format (`cs-CZ`) required by Apple Vision OCR
- **Fixed engine selection**: Corrected issue where Tesseract engine was being selected even when disabled in preferences, causing fallback to incorrect engines with poor results
- **Language identifier handling**: Improved `LanguageCodeMapper.standardize()` to properly handle locale-based language codes

### Image Preprocessing
- **Enhanced text recognition accuracy**: Added automatic image preprocessing with:
  - +30% contrast enhancement
  - +10% brightness adjustment
  - +10% saturation boost
- These improvements help recognize low-contrast and light-colored text more reliably

## 🔗 Links

- [Full Changelog](https://github.com/amebalabs/TRex/compare/v1.9.0...v1.9.1)
- [GitHub Release](https://github.com/amebalabs/TRex/releases/tag/v1.9.1)

# v1.9.1-BETA-3 (2025-11-05)

# TRex v1.9.1-BETA-3 Release Notes

## 🛠 Fixes

- Improving CLI downloader

# v1.9.1-BETA-2 (2025-11-04)

# TRex v1.9.1-BETA-2 Release Notes

## 🛠 Fixes

- **Release pipeline reliability**: Resolved GitHub Actions caching conflicts by moving the CLI binary into an isolated build cache directory, preventing restore failures when staging artifacts for signing and notarization.
- **Notarization flow guardrails**: Ensured the CLI binary stays signed/notarized in-place, simplifying the notarization submission and reducing chances of entitlement-related errors during packaging.

## 🔧 Improvements

- **CI transparency**: Added targeted logging around staging the CLI artifact during signing and release so troubleshooting future release runs is faster.

## ✅ Deployment Notes

- This build is intended to exercise the full release pipeline end-to-end. Tag the repository with `v1.9.1-BETA-2` to trigger the release workflow once you are ready.

# v1.9.1-BETA-1 (2025-10-15)

# TRex v1.9.1-BETA-1 Release Notes

## 🐛 Bug Fixes

### Czech Language OCR Fix
- **Fixed language code normalization**: Resolved issues with Czech (and potentially other) language recognition where language codes with underscores (`cs_CZ`) weren't being properly converted to the hyphen format (`cs-CZ`) required by Apple Vision OCR
- **Fixed engine selection**: Corrected issue where Tesseract engine was being selected even when disabled in preferences, causing fallback to incorrect engines with poor results
- **Language identifier handling**: Improved `LanguageCodeMapper.standardize()` to properly handle locale-based language codes

### Image Preprocessing
- **Enhanced text recognition accuracy**: Added automatic image preprocessing with:
  - +30% contrast enhancement
  - +10% brightness adjustment
  - +10% saturation boost
- These improvements help recognize low-contrast and light-colored text more reliably

### OCR Engine Management
- **Better engine routing**: Made `OCRManager.engines` publicly readable to allow proper engine filtering based on user preferences
- **Explicit Vision engine selection**: Ensures Apple Vision is used when Tesseract is disabled

## 🔧 Improvements

### Developer Experience
- **Enhanced logging**: Added comprehensive debug logging throughout the OCR pipeline, including:
  - Language selection decisions
  - Engine routing information
  - Recognition results with confidence scores
  - Alternate recognition candidates for debugging

### Code Quality
- **Removed unnecessary entitlements**: Cleaned up app entitlements file by removing unneeded permissions

## 📝 Technical Details

This release primarily addresses language recognition issues that could affect users working with Czech and potentially other languages where locale-based language codes (containing underscores or region identifiers) weren't being properly standardized for the Vision framework.

# v1.9.1-BETA-1 (2025-10-15)

# TRex v1.9.1-BETA-1 Release Notes

## 🐛 Bug Fixes

### Czech Language OCR Fix
- **Fixed language code normalization**: Resolved issues with Czech (and potentially other) language recognition where language codes with underscores (`cs_CZ`) weren't being properly converted to the hyphen format (`cs-CZ`) required by Apple Vision OCR
- **Fixed engine selection**: Corrected issue where Tesseract engine was being selected even when disabled in preferences, causing fallback to incorrect engines with poor results
- **Language identifier handling**: Improved `LanguageCodeMapper.standardize()` to properly handle locale-based language codes

### Image Preprocessing
- **Enhanced text recognition accuracy**: Added automatic image preprocessing with:
  - +30% contrast enhancement
  - +10% brightness adjustment
  - +10% saturation boost
- These improvements help recognize low-contrast and light-colored text more reliably

### OCR Engine Management
- **Better engine routing**: Made `OCRManager.engines` publicly readable to allow proper engine filtering based on user preferences
- **Explicit Vision engine selection**: Ensures Apple Vision is used when Tesseract is disabled

## 🔧 Improvements

### Developer Experience
- **Enhanced logging**: Added comprehensive debug logging throughout the OCR pipeline, including:
  - Language selection decisions
  - Engine routing information
  - Recognition results with confidence scores
  - Alternate recognition candidates for debugging

### Code Quality
- **Removed unnecessary entitlements**: Cleaned up app entitlements file by removing unneeded permissions

## 📝 Technical Details

This release primarily addresses language recognition issues that could affect users working with Czech and potentially other languages where locale-based language codes (containing underscores or region identifiers) weren't being properly standardized for the Vision framework.

# v1.9.0 (2025-10-15)

# TRex v1.9.0 Release Notes

## ✨ What's New

### Enhanced Language Support
- **Tesseract OCR Engine**: Added support for 100+ languages through Tesseract OCR
- **Intelligent Engine Selection**: TRex automatically chooses the best OCR engine (Apple Vision or Tesseract) based on the selected language
- **Comprehensive Language Coverage**: Now supports languages from Afrikaans to Yoruba, including complex scripts like Arabic, Chinese, Japanese, and many more

### Automatic Updates
- **Sparkle Integration**: TRex now supports automatic updates! The app checks for new versions and notifies you when updates are available
- **Manual Check**: Check for updates anytime from Settings → General or the menu bar
- **Beta Channel**: Opt into beta updates to get early access to new features

### Compatibility
- Fixed compatibility with macOS 15.0+ for Option (⌥) symbol display
- Requires macOS 13.0+ for enhanced OCR features

# v1.9.0-BETA-5 (2025-10-15)

# TRex v1.9.0-BETA-5 Release Notes

## 🐛 Bug Fixes

### Tesseract Language Download Fixes
- **Fixed language mapping**: Added comprehensive ISO 639-1 to ISO 639-3 mapping for ~75 additional languages
- **Resolved download failures**: Languages like Slovak (sk), Romanian (ro), Bulgarian (bg), Croatian (hr), Indonesian (id), and many more now download correctly
- Previously, only 27 languages were mapped, causing "Language not supported" errors for the remaining 80+ languages that Tesseract supports
- Tesseract language downloads now work for all 107 supported languages

## 🔧 Improvements

### Auto-Update Configuration
- Fixed GitHub Pages URLs to use correct repository path (amebalabs.github.io/TRex)
- Streamlined release workflow to deploy directly to main branch
- Improved appcast feed configuration for more reliable update delivery

## 📝 Technical Details

- Comprehensive language code mapping now covers all languages supported by both Apple Vision Framework and Tesseract OCR
- Bidirectional mapping ensures proper conversion between ISO 639-1 (Vision) and ISO 639-3 (Tesseract) codes

