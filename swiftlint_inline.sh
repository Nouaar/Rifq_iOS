#!/bin/bash
# Inline SwiftLint script - use this directly in Xcode Build Phase
# Copy the content below into Xcode's "Run Script" phase (don't reference this file)

if which swiftlint >/dev/null 2>&1; then
    swiftlint
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi

