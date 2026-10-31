#!/bin/bash
# Stop ClaudeBuddy and remove the login item + app.
LABEL=com.claudebuddy.agent
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Applications/ClaudeBuddy.app"
pkill -x ClaudeBuddy 2>/dev/null || true
echo "Removed. (Your settings in ~/.claude-buddy are kept.)"
