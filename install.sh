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

# One daemon only — stop our agent and any Homebrew service copy.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootout "gui/$(id -u)/homebrew.mxcl.threefinger" 2>/dev/null || true
brew services stop threefinger 2>/dev/null || true
mkdir -p "$BINDIR" "$AGENTS"
if cmp -s "$tmp/threefinger" "$BINDIR/threefinger"; then
    replaced=0
else
    replaced=1
    install -m 755 "$tmp/threefinger" "$BINDIR/threefinger"
fi
sed "s|/usr/local/bin|$BINDIR|" "$tmp/$LABEL.plist" > "$AGENTS/$LABEL.plist"
launchctl bootstrap "gui/$(id -u)" "$AGENTS/$LABEL.plist"

cat <<EOF

Installed: $BINDIR/threefinger

Permissions:
EOF
"$BINDIR/threefinger" --check --open || true

cat <<EOF

Next:
  1. If Accessibility / Input Monitoring is MISSING above — add:
       $BINDIR/threefinger
EOF
if [ "$replaced" = 1 ]; then
    cat <<EOF
     (binary was replaced — remove the old entry (−) first, then re-add;
      toggling the switch is not enough)
EOF
fi
cat <<'EOF'
  2. Trackpad → More Gestures (opened when Accessibility is granted)
       Swipe between full-screen applications  → Swipe Left or Right with Four Fingers  (required)
       Swipe between pages                     → Off  (optional, recommended)

Default: 3-finger swipe ←/→ switches tabs (Ctrl-Shift-Tab / Ctrl-Tab)
Config:  ~/.config/threefinger.json

EOF
