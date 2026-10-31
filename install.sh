#!/bin/bash
# Build ClaudeBuddy, install it as ~/Applications/ClaudeBuddy.app and start it at every login.
set -euo pipefail
cd "$(dirname "$0")"
LABEL=com.claudebuddy.agent
APP="$HOME/Applications/ClaudeBuddy.app"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/ClaudeBuddy"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
pkill -x ClaudeBuddy 2>/dev/null || true

mkdir -p "$APP/Contents/MacOS" "$HOME/Library/LaunchAgents" "$HOME/.claude-buddy"
cp "$BIN" "$APP/Contents/MacOS/ClaudeBuddy"
cat > "$APP/Contents/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.claudebuddy.app</string>
  <key>CFBundleName</key><string>ClaudeBuddy</string>
  <key>CFBundleExecutable</key><string>ClaudeBuddy</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PL
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$APP/Contents/MacOS/ClaudeBuddy</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ProcessType</key><string>Interactive</string>
  <key>StandardOutPath</key><string>$HOME/.claude-buddy/buddy.log</string>
  <key>StandardErrorPath</key><string>$HOME/.claude-buddy/buddy.log</string>
</dict></plist>
PL

launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed. ClaudeBuddy now starts at every login (Quit from the 🍌 menu stops it until next login)."
