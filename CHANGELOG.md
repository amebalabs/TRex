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

