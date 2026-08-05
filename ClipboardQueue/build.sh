#!/bin/bash
# Builds ClipboardQueue and assembles a runnable .app bundle (no Xcode required).
set -euo pipefail

cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP="build/Clipboard Queue.app"

swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/ClipboardQueue"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ClipboardQueue"
cp Resources/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Ad-hoc signature so the global hot keys and pasteboard access behave across rebuilds.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "Built $APP"
echo "Run with: open \"$APP\"   (or: \"$APP/Contents/MacOS/ClipboardQueue\")"
