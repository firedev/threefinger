#!/bin/bash
# threefinger uninstaller — stops the daemon, removes binary and LaunchAgent.
# curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/uninstall.sh | bash
set -euo pipefail

LABEL=com.firedev.threefinger
BINDIR="${BINDIR:-$HOME/.local/bin}"
AGENTS="${AGENTS:-$HOME/Library/LaunchAgents}"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$BINDIR/threefinger" "$AGENTS/$LABEL.plist"

echo ">>> Uninstalled."
