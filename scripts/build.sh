#!/bin/bash

set -e

cd "$(dirname "$0")/.."

# Ensure Xcode is selected
if [ -d "/Applications/Xcode.app" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

echo "Building Sukasi..."

xcodebuild \
    -project Sukasi.xcodeproj \
    -scheme Sukasi \
    -configuration Debug \
    build

echo "Build completed successfully!"
