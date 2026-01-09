#!/bin/bash

set -e

cd "$(dirname "$0")/.."

# Ensure Xcode is selected
if [ -d "/Applications/Xcode.app" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

echo "Cleaning Sukasi..."

xcodebuild \
    -project Sukasi.xcodeproj \
    -scheme Sukasi \
    clean

echo "Clean completed successfully!"
