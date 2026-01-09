#!/bin/bash

set -e

cd "$(dirname "$0")/.."

# Ensure Xcode is selected
if [ -d "/Applications/Xcode.app" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

# Build first
./scripts/build.sh

# Get the build directory from xcodebuild
BUILD_DIR=$(xcodebuild -project Sukasi.xcodeproj -scheme Sukasi -showBuildSettings 2>/dev/null | grep -m 1 "BUILT_PRODUCTS_DIR" | sed 's/.*= //')

if [ -z "$BUILD_DIR" ]; then
    echo "Error: Could not determine build directory"
    exit 1
fi

APP_PATH="$BUILD_DIR/Sukasi.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

echo "Launching Sukasi..."
open "$APP_PATH"
