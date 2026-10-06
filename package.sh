#!/bin/bash
# Builds Reminder.app, installs it to ~/Applications and registers it to start at login.
set -euo pipefail
cd "$(dirname "$0")"

APP="$HOME/Applications/Reminder.app"
LABEL="com.riya.reminder"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
pkill -x Reminder 2>/dev/null || true

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Reminder" "$APP/Contents/MacOS/Reminder"
cp -R "$BIN_DIR/Reminder_Reminder.bundle" "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>$LABEL</string>
  <key>CFBundleName</key><string>Reminder</string>
  <key>CFBundleExecutable</key><string>Reminder</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PL
codesign --force --deep --sign - "$APP"

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$APP/Contents/MacOS/Reminder</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
PL
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed $APP and enabled start at login."
