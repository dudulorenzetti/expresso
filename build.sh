#!/bin/bash
# Compila o Expresso com as Command Line Tools (sem Xcode) e assina ad hoc.
set -euo pipefail
cd "$(dirname "$0")"
APP=build/Expresso.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
cp Expresso.icns "$APP/Contents/Resources/Expresso.icns"
xcrun --sdk macosx swiftc -O -target arm64-apple-macos13.0 \
  -framework AppKit -framework IOKit main.swift -o "$APP/Contents/MacOS/Expresso"
codesign --force --sign - "$APP"
codesign --verify --verbose=2 "$APP"
echo "Pronto: $(pwd)/$APP"
