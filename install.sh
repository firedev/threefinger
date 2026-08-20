#!/bin/bash
# threefinger installer — latest release binary, no clone, no build.
# curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/install.sh | bash
set -euo pipefail

REPO=firedev/threefinger
LABEL=com.firedev.threefinger
BINDIR="${BINDIR:-$HOME/.local/bin}"
AGENTS="${AGENTS:-$HOME/Library/LaunchAgents}"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fsSL "https://github.com/$REPO/releases/latest/download/threefinger-arm64.tar.gz" | tar xz -C "$tmp"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
mkdir -p "$BINDIR" "$AGENTS"
install -m 755 "$tmp/threefinger" "$BINDIR/threefinger"
sed "s|/usr/local/bin|$BINDIR|" "$tmp/$LABEL.plist" > "$AGENTS/$LABEL.plist"
launchctl bootstrap "gui/$(id -u)" "$AGENTS/$LABEL.plist"

echo ">>> Installed and loaded ($BINDIR/threefinger)."
echo ">>> Grant Accessibility to the BINARY itself: System Settings → Privacy & Security → Accessibility → + → $BINDIR/threefinger."
echo ">>> Re-grant after every update that replaces the file — swipes silently stop posting otherwise."
