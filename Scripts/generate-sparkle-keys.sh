#!/bin/bash

# Script to generate Sparkle EdDSA keys for code signing updates

set -e

echo "Generating Sparkle EdDSA key pair..."

# Download Sparkle if not present
if [ ! -f "generate_keys" ]; then
    SPARKLE_VERSION="2.6.4"
    echo "Downloading Sparkle $SPARKLE_VERSION..."
    curl -L -o sparkle.tar.xz "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz"
    tar -xf sparkle.tar.xz
    cp Sparkle.framework/Versions/Current/bin/generate_keys .
    rm -rf sparkle.tar.xz Sparkle.framework
    chmod +x generate_keys
fi

# Generate keys
./generate_keys

echo ""
echo "Keys generated successfully!"
echo ""
echo "IMPORTANT: Follow these steps:"
echo ""
echo "1. Add the PUBLIC key to your app's Info.plist:"
echo "   Key: SUPublicEDKey"
echo "   Value: [public key shown above]"
echo ""
echo "2. Add the PRIVATE key to GitHub Secrets:"
echo "   Name: SPARKLE_PRIVATE_KEY"
echo "   Value: [private key shown above]"
echo ""
echo "3. Keep the private key secure and never commit it to the repository!"
echo ""
echo "4. For the beta channel, you may want to use a different key pair."