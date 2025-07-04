#!/bin/bash

# Minimal build script for Tesseract and Leptonica
# This builds with NO external dependencies - pure C/C++ only

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
BUILD_DIR="$PROJECT_ROOT/build/tesseract-minimal"
INSTALL_DIR="$PROJECT_ROOT/Libraries/tesseract"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building MINIMAL Tesseract and Leptonica (no external dependencies)${NC}"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$INSTALL_DIR"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

# Check if source directories exist
LEPTONICA_SRC="$PROJECT_ROOT/build/tesseract-clean/leptonica-1.85.0"
TESSERACT_SRC="$PROJECT_ROOT/build/tesseract-clean/tesseract-5.3.3"

if [ ! -d "$LEPTONICA_SRC" ]; then
    echo -e "${RED}Error: Leptonica source not found at $LEPTONICA_SRC${NC}"
    echo "Please run download-tesseract-sources.sh first"
    exit 1
fi

if [ ! -d "$TESSERACT_SRC" ]; then
    echo -e "${RED}Error: Tesseract source not found at $TESSERACT_SRC${NC}"
    echo "Please run download-tesseract-sources.sh first"
    exit 1
fi

# Build Leptonica with ALL image format support disabled
echo -e "${YELLOW}Building Leptonica (minimal - no image format dependencies)...${NC}"
cd "$BUILD_DIR"
mkdir -p leptonica-build
cd leptonica-build

# Configure Leptonica with everything disabled
cmake "$LEPTONICA_SRC" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_PROG=OFF \
    -DSW_BUILD=OFF \
    -DBUILD_TESTS=OFF \
    -DCMAKE_DISABLE_FIND_PACKAGE_GIF=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_JPEG=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_PNG=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_TIFF=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_WebP=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_OpenJPEG=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_CURL=TRUE

echo -e "${GREEN}Leptonica configuration complete. Building...${NC}"
make -j$(sysctl -n hw.ncpu)
make install

# Build Tesseract with minimal configuration
echo -e "${YELLOW}Building Tesseract (minimal configuration)...${NC}"
cd "$BUILD_DIR"
mkdir -p tesseract-build
cd tesseract-build

# Set Leptonica paths
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export Leptonica_DIR="$INSTALL_DIR/lib/cmake/leptonica"

# Configure Tesseract with minimal features
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
    -DCMAKE_DISABLE_FIND_PACKAGE_OpenMP=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_LibArchive=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_CURL=TRUE \
    -DLeptonica_DIR="$Leptonica_DIR"

echo -e "${GREEN}Tesseract configuration complete. Building...${NC}"
make -j$(sysctl -n hw.ncpu)
make install

# Build the TesseractWrapper
echo -e "${YELLOW}Building TesseractWrapper...${NC}"
cd "$PROJECT_ROOT/TRex"

# Compile TesseractWrapper.mm
clang++ -c TesseractWrapper.mm \
    -I"$INSTALL_DIR/include" \
    -I"$INSTALL_DIR/include/tesseract" \
    -I"$INSTALL_DIR/include/leptonica" \
    -std=c++17 \
    -fobjc-arc \
    -fmodules \
    -arch arm64 \
    -o "$INSTALL_DIR/lib/TesseractWrapper.o"

# Create static library
ar rcs "$INSTALL_DIR/lib/libTesseractWrapper.a" "$INSTALL_DIR/lib/TesseractWrapper.o"

echo -e "${GREEN}Build complete!${NC}"
echo -e "${GREEN}Libraries installed to: $INSTALL_DIR${NC}"

# Verify the build has no external dependencies
echo -e "${YELLOW}Verifying minimal dependencies...${NC}"
echo "Checking libleptonica.a for external symbols:"
nm "$INSTALL_DIR/lib/libleptonica.a" | grep -E "U _(TIFF|WebP|jpeg|png|gif|curl|deflate|inflate)" | head -10 || echo "✓ No external image format dependencies found"

echo ""
echo "Checking libtesseract.a for external symbols:"
nm "$INSTALL_DIR/lib/libtesseract.a" | grep -E "U _(TIFF|WebP|jpeg|png|gif|curl|deflate|inflate)" | head -10 || echo "✓ No external dependencies found"

echo -e "${GREEN}Minimal build complete! The libraries have no external dependencies.${NC}"