#!/bin/bash

# Build script for Tesseract and Leptonica (ARM64 only)
# This script builds static libraries for embedding in TRex

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
BUILD_DIR="$PROJECT_ROOT/build/tesseract-libs"
INSTALL_DIR="$PROJECT_ROOT/Libraries/tesseract"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building Tesseract and Leptonica for ARM64${NC}"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

# Check if source directories exist
LEPTONICA_SRC="$PROJECT_ROOT/build/tesseract-clean/leptonica-1.85.0"
TESSERACT_SRC="$PROJECT_ROOT/build/tesseract-clean/tesseract-5.3.3"

if [ ! -d "$LEPTONICA_SRC" ]; then
    echo -e "${RED}Error: Leptonica source not found at $LEPTONICA_SRC${NC}"
    exit 1
fi

if [ ! -d "$TESSERACT_SRC" ]; then
    echo -e "${RED}Error: Tesseract source not found at $TESSERACT_SRC${NC}"
    exit 1
fi

# Build Leptonica first (Tesseract dependency)
echo -e "${YELLOW}Building Leptonica...${NC}"
cd "$BUILD_DIR"
mkdir -p leptonica-build
cd leptonica-build

cmake "$LEPTONICA_SRC" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_PROG=OFF \
    -DSW_BUILD=OFF \
    -DBUILD_TESTS=OFF \
    -DCMAKE_C_FLAGS="-fembed-bitcode" \
    -DCMAKE_CXX_FLAGS="-fembed-bitcode" \
    -DCMAKE_DISABLE_FIND_PACKAGE_GIF=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_WebP=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_OpenJPEG=TRUE

make -j$(sysctl -n hw.ncpu)
make install

# Build Tesseract
echo -e "${YELLOW}Building Tesseract...${NC}"
cd "$BUILD_DIR"
mkdir -p tesseract-build
cd tesseract-build

# Set Leptonica paths
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export Leptonica_DIR="$INSTALL_DIR/lib/cmake/leptonica"

cmake "$TESSERACT_SRC" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TRAINING_TOOLS=OFF \
    -DBUILD_TESTS=OFF \
    -DSW_BUILD=OFF \
    -DGRAPHICS_DISABLED=ON \
    -DDISABLED_LEGACY_ENGINE=OFF \
    -DENABLE_LTO=OFF \
    -DCMAKE_C_FLAGS="-fembed-bitcode" \
    -DCMAKE_CXX_FLAGS="-fembed-bitcode -std=c++17" \
    -DLeptonica_DIR="$Leptonica_DIR"

make -j$(sysctl -n hw.ncpu)
make install

# Create module map for Swift C++ interop
echo -e "${YELLOW}Creating module maps...${NC}"
mkdir -p "$INSTALL_DIR/include/tesseract/module"
cat > "$INSTALL_DIR/include/tesseract/module/module.modulemap" << 'EOF'
module CTesseract {
    header "../baseapi.h"
    header "../capi.h"
    header "../renderer.h"
    header "../resultiterator.h"
    header "../pageiterator.h"
    header "../publictypes.h"
    header "../unichar.h"
    export *
    
    link "tesseract"
    link "leptonica"
    
    use CLeptonica
}

module CLeptonica {
    header "../../leptonica/allheaders.h"
    export *
    link "leptonica"
}
EOF

# Create a C++ wrapper header for Swift interop
echo -e "${YELLOW}Creating Swift C++ interop header...${NC}"
cat > "$INSTALL_DIR/include/TesseractSwiftBridge.h" << 'EOF'
#ifndef TESSERACT_SWIFT_BRIDGE_H
#define TESSERACT_SWIFT_BRIDGE_H

#ifdef __cplusplus

#include <memory>
#include <string>
#include <vector>
#include <tesseract/baseapi.h>
#include <leptonica/allheaders.h>

namespace TesseractSwift {

class TesseractWrapper {
private:
    std::unique_ptr<tesseract::TessBaseAPI> api;
    
public:
    TesseractWrapper();
    ~TesseractWrapper();
    
    bool initialize(const char* datapath, const char* language);
    void setPageSegMode(tesseract::PageSegMode mode);
    
    // Process image from raw pixel data
    bool setImage(const unsigned char* imagedata, int width, int height, 
                  int bytes_per_pixel, int bytes_per_line);
    
    // Get recognized text
    std::string getUTF8Text();
    
    // Get confidence
    int getMeanTextConfidence();
    
    // Clear current recognition
    void clear();
    
    // Get available languages
    static std::vector<std::string> getAvailableLanguages(const char* datapath);
};

// Helper function to convert CGImage data
bool processImageData(TesseractWrapper& tess, const unsigned char* data, 
                     int width, int height, int bytesPerRow);

} // namespace TesseractSwift

#endif // __cplusplus

#endif // TESSERACT_SWIFT_BRIDGE_H
EOF

# Create implementation file
cat > "$INSTALL_DIR/include/TesseractSwiftBridge.cpp" << 'EOF'
#include "TesseractSwiftBridge.h"
#include <dirent.h>
#include <cstring>

namespace TesseractSwift {

TesseractWrapper::TesseractWrapper() : api(std::make_unique<tesseract::TessBaseAPI>()) {}

TesseractWrapper::~TesseractWrapper() {
    if (api) {
        api->End();
    }
}

bool TesseractWrapper::initialize(const char* datapath, const char* language) {
    return api->Init(datapath, language) == 0;
}

void TesseractWrapper::setPageSegMode(tesseract::PageSegMode mode) {
    api->SetPageSegMode(mode);
}

bool TesseractWrapper::setImage(const unsigned char* imagedata, int width, int height, 
                               int bytes_per_pixel, int bytes_per_line) {
    api->SetImage(imagedata, width, height, bytes_per_pixel, bytes_per_line);
    return true;
}

std::string TesseractWrapper::getUTF8Text() {
    char* text = api->GetUTF8Text();
    std::string result(text ? text : "");
    delete[] text;
    return result;
}

int TesseractWrapper::getMeanTextConfidence() {
    return api->MeanTextConf();
}

void TesseractWrapper::clear() {
    api->Clear();
}

std::vector<std::string> TesseractWrapper::getAvailableLanguages(const char* datapath) {
    std::vector<std::string> languages;
    
    DIR* dir = opendir(datapath);
    if (dir) {
        struct dirent* entry;
        while ((entry = readdir(dir)) != nullptr) {
            std::string filename(entry->d_name);
            const std::string suffix = ".traineddata";
            if (filename.length() > suffix.length() && 
                filename.substr(filename.length() - suffix.length()) == suffix) {
                languages.push_back(filename.substr(0, filename.length() - suffix.length()));
            }
        }
        closedir(dir);
    }
    
    return languages;
}

bool processImageData(TesseractWrapper& tess, const unsigned char* data, 
                     int width, int height, int bytesPerRow) {
    // Assume RGBA format from CGImage
    return tess.setImage(data, width, height, 4, bytesPerRow);
}

} // namespace TesseractSwift
EOF

echo -e "${GREEN}Build complete!${NC}"
echo -e "${GREEN}Libraries installed at: $INSTALL_DIR${NC}"
echo ""
echo "Next steps:"
echo "1. Run: ./Scripts/download-tessdata.sh"
echo "2. Update Package.swift to include the libraries"
echo "3. Import and use in Swift with C++ interop"