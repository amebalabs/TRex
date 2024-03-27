#!/bin/bash

# Note: TRex v1.7.0 required
# Install from https://trex.ameba.co

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Capture Text From Clipboard
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ./images/trex.icns
# @raycast.packageName TRex

# Documentation:
# @raycast.author Ameba Labs
# @raycast.authorURL https://github.com/amebalabs
# @raycast.description Extracts text from image in clipboard

open "trex://captureclipboard"
