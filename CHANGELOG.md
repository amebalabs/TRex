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

