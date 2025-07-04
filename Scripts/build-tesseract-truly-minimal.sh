#!/bin/bash

# Truly minimal build script for Tesseract and Leptonica
# This builds with ABSOLUTELY NO external dependencies

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

echo -e "${GREEN}Building TRULY MINIMAL Tesseract and Leptonica (zero dependencies)${NC}"

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
    exit 1
fi

if [ ! -d "$TESSERACT_SRC" ]; then
    echo -e "${RED}Error: Tesseract source not found at $TESSERACT_SRC${NC}"
    exit 1
fi

# Build Leptonica with ALL features disabled
echo -e "${YELLOW}Building Leptonica (zero dependencies)...${NC}"
cd "$BUILD_DIR"
mkdir -p leptonica-build
cd leptonica-build

# Configure with everything explicitly disabled
cmake "$LEPTONICA_SRC" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_PROG=OFF \
    -DSW_BUILD=OFF \
    -DBUILD_TESTS=OFF \
    -DENABLE_GIF=OFF \
    -DENABLE_JPEG=OFF \
    -DENABLE_PNG=OFF \
    -DENABLE_TIFF=OFF \
    -DENABLE_ZLIB=OFF \
    -DENABLE_WEBP=OFF \
    -DENABLE_OPENJPEG=OFF

echo -e "${GREEN}Building Leptonica...${NC}"
make -j$(sysctl -n hw.ncpu)
make install

# Verify no dependencies
echo -e "${YELLOW}Verifying Leptonica has no external dependencies...${NC}"
DEPS=$(nm "$INSTALL_DIR/lib/libleptonica.a" 2>/dev/null | grep -E "U _(TIFF|WebP|jpeg|png|gif|curl|deflate|inflate|JP2)" | wc -l || echo "0")
if [ "$DEPS" -ne "0" ]; then
    echo -e "${RED}ERROR: Leptonica still has external dependencies!${NC}"
    nm "$INSTALL_DIR/lib/libleptonica.a" | grep -E "U _(TIFF|WebP|jpeg|png|gif|curl|deflate|inflate|JP2)" | head -20
    exit 1
fi
echo -e "${GREEN}✓ Leptonica has no external dependencies${NC}"

# Build Tesseract
echo -e "${YELLOW}Building Tesseract (minimal)...${NC}"
cd "$BUILD_DIR"
mkdir -p tesseract-build
cd tesseract-build

# Set Leptonica paths
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export Leptonica_DIR="$INSTALL_DIR/lib/cmake/leptonica"

# Configure Tesseract
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

echo -e "${GREEN}Building Tesseract...${NC}"
make -j$(sysctl -n hw.ncpu)
make install

# Build TesseractWrapper
echo -e "${YELLOW}Building TesseractWrapper...${NC}"
cd "$PROJECT_ROOT/TRex"

clang++ -c TesseractWrapper.mm \
    -I"$INSTALL_DIR/include" \
    -I"$INSTALL_DIR/include/tesseract" \
    -I"$INSTALL_DIR/include/leptonica" \
    -std=c++17 \
    -fobjc-arc \
    -fmodules \
    -arch arm64 \
    -o "$INSTALL_DIR/lib/TesseractWrapper.o"

ar rcs "$INSTALL_DIR/lib/libTesseractWrapper.a" "$INSTALL_DIR/lib/TesseractWrapper.o"

# Final verification
echo -e "${YELLOW}Final verification of dependencies...${NC}"
echo "Checking libleptonica.a:"
LEPT_DEPS=$(nm "$INSTALL_DIR/lib/libleptonica.a" 2>/dev/null | grep -E "U _(TIFF|WebP|jpeg|png|gif|curl|deflate|inflate|JP2)" | wc -l || echo "0")
echo "  External dependencies: $LEPT_DEPS"

echo "Checking libtesseract.a:"
TESS_DEPS=$(nm "$INSTALL_DIR/lib/libtesseract.a" 2>/dev/null | grep -E "U _(TIFF|WebP|jpeg|png|gif|curl|deflate|inflate|JP2)" | wc -l || echo "0")
echo "  External dependencies: $TESS_DEPS"

if [ "$LEPT_DEPS" -eq "0" ] && [ "$TESS_DEPS" -eq "0" ]; then
    echo -e "${GREEN}SUCCESS! Libraries have zero external dependencies.${NC}"
else
    echo -e "${RED}WARNING: Libraries still have some external dependencies.${NC}"
fi

echo -e "${GREEN}Build complete! Libraries installed to: $INSTALL_DIR${NC}"