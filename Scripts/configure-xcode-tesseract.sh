#!/bin/bash

# Script to configure Xcode project for Tesseract library integration

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
LIBRARIES_DIR="$PROJECT_ROOT/Libraries/tesseract"

echo "Configuring Xcode project for Tesseract integration..."

# Ensure the xcconfig directory exists
mkdir -p "$PROJECT_ROOT/Configuration"

# Create xcconfig file for Tesseract settings
cat > "$PROJECT_ROOT/Configuration/Tesseract.xcconfig" << EOF
// Tesseract Library Configuration

// Header search paths
HEADER_SEARCH_PATHS = \$(inherited) "\$(PROJECT_DIR)/Libraries/tesseract/include"

// Library search paths
LIBRARY_SEARCH_PATHS = \$(inherited) "\$(PROJECT_DIR)/Libraries/tesseract/lib"

// Other linker flags
OTHER_LDFLAGS = \$(inherited) -lTesseractWrapper -ltesseract -lleptonica -lc++

// Enable modules for Objective-C++
CLANG_ENABLE_MODULES = YES

// Module map file
MODULEMAP_FILE = \$(PROJECT_DIR)/Libraries/tesseract/include/module.modulemap

// Swift import paths
SWIFT_INCLUDE_PATHS = \$(inherited) "\$(PROJECT_DIR)/Libraries/tesseract/include"
EOF

echo "Created Tesseract.xcconfig"

# Create a bridging header if needed
cat > "$PROJECT_ROOT/Packages/TRexCore/Sources/TRexCore/TesseractBridge.h" << 'EOF'
#ifndef TesseractBridge_h
#define TesseractBridge_h

#import <TesseractWrapper/TesseractWrapper.h>

#endif /* TesseractBridge_h */
EOF

echo "Created bridging header"

echo ""
echo "Configuration complete!"
echo ""
echo "Next steps:"
echo "1. Open TRex.xcodeproj in Xcode"
echo "2. Select the TRex target"
echo "3. Go to Build Settings"
echo "4. Under 'User-Defined', add: #include \"../Configuration/Tesseract.xcconfig\""
echo "5. Do the same for the TRexCore framework target"
echo ""
echo "Or run: xcodebuild -scheme TRex -configuration Debug build"