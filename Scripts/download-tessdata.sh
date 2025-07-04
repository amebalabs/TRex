#!/bin/bash

# Download essential Tesseract language data files

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
TESSDATA_DIR="$PROJECT_ROOT/Resources/tessdata"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Downloading Tesseract language data files${NC}"

# Create tessdata directory
mkdir -p "$TESSDATA_DIR"

# Base URL for tessdata_best (highest quality)
BASE_URL="https://github.com/tesseract-ocr/tessdata_best/raw/main"

# Essential languages to download
LANGUAGES=(
    "eng"     # English
    "fra"     # French  
    "deu"     # German
    "spa"     # Spanish
    "ita"     # Italian
    "por"     # Portuguese
    "rus"     # Russian
    "jpn"     # Japanese
    "chi_sim" # Chinese Simplified
    "chi_tra" # Chinese Traditional
    "kor"     # Korean
    "ara"     # Arabic
    "hin"     # Hindi
)

# Download each language file
for lang in "${LANGUAGES[@]}"; do
    FILE="$lang.traineddata"
    URL="$BASE_URL/$FILE"
    OUTPUT="$TESSDATA_DIR/$FILE"
    
    if [ -f "$OUTPUT" ]; then
        echo -e "${YELLOW}$FILE already exists, skipping${NC}"
    else
        echo -e "${GREEN}Downloading $FILE...${NC}"
        curl -L -o "$OUTPUT" "$URL"
    fi
done

echo -e "${GREEN}Download complete!${NC}"
echo -e "${GREEN}Language files saved to: $TESSDATA_DIR${NC}"
echo ""
echo "Total size:"
du -sh "$TESSDATA_DIR"