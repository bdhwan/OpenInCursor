#!/bin/bash

# Build the app without code signing
echo "Building Open in Cursor..."

# Create the output directory
mkdir -p build/Release

# Compile the main.m file
xcrun clang -framework Cocoa -framework ScriptingBridge -target arm64-apple-macos10.13 -o build/OpenInCursor main.m

if [ $? -ne 0 ]; then
    echo "Error: Compilation failed."
    exit 1
fi

# Create the app bundle structure
echo "Creating app bundle..."
mkdir -p "build/Open in Cursor.app/Contents/MacOS"
mkdir -p "build/Open in Cursor.app/Contents/Resources"

# Copy the binary to the app bundle
cp build/OpenInCursor "build/Open in Cursor.app/Contents/MacOS/Open in Cursor"

# Copy the Info.plist file to the app bundle
cp Info.plist "build/Open in Cursor.app/Contents/"

# Copy the icon to the app bundle
cp icon.icns "build/Open in Cursor.app/Contents/Resources/"

# Create PkgInfo file
echo "APPLcur " > "build/Open in Cursor.app/Contents/PkgInfo"

# Code sign the app with entitlements
echo "Code signing app with entitlements..."
codesign --force --deep --sign - --entitlements OpenInCursor.entitlements "build/Open in Cursor.app"

echo "Build complete. App is in build/Open in Cursor.app" 