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
if cmp -s "$tmp/threefinger" "$BINDIR/threefinger"; then
    replaced=0
else
    replaced=1
    install -m 755 "$tmp/threefinger" "$BINDIR/threefinger"
fi
sed "s|/usr/local/bin|$BINDIR|" "$tmp/$LABEL.plist" > "$AGENTS/$LABEL.plist"
launchctl bootstrap "gui/$(id -u)" "$AGENTS/$LABEL.plist"

echo ">>> Installed and loaded ($BINDIR/threefinger)."
if [ "$replaced" = 1 ]; then
    echo ">>> Binary was replaced, so its Accessibility grant is void: System Settings → Privacy & Security → Accessibility → remove threefinger (−), then + → $BINDIR/threefinger. Toggling the switch is not enough."
else
    echo ">>> Binary unchanged — existing Accessibility grant still valid."
fi
