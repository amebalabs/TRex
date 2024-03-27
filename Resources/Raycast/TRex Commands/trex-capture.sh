#!/bin/bash

# Note: TRex v1.7.0 required
# Install from https://trex.ameba.co

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Capture Text
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ./images/trex.icns
# @raycast.packageName TRex

# Documentation:
# @raycast.author Ameba Labs
# @raycast.authorURL https://github.com/amebalabs
# @raycast.description Opens Text Recognition (OCR) tool or extracts text from the specified file.

open "trex://capture"
