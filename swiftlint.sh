#!/bin/bash

# SwiftLint Script for Xcode Build Phase
# Add this as a "Run Script" build phase in Xcode
# Use: "${SRCROOT}/swiftlint.sh" or "${PROJECT_DIR}/swiftlint.sh"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if which swiftlint >/dev/null; then
    swiftlint
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
    exit 0
fi

