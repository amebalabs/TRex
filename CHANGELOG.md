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

