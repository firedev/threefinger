# threefinger

Three-finger horizontal swipe on the macOS trackpad → any keyboard shortcut. A tiny single-file replacement for that one BetterTouchTool feature. Default: swipe left posts ⌥⌘←, swipe right posts ⌥⌘→. One action per swipe; re-arms when all fingers lift.

**Why:** BetterTouchTool is paid, and nothing open source maps trackpad gestures to keyboard shortcuts. This does exactly that, in ~90 lines of Swift on the private `MultitouchSupport.framework`.

## Install

```sh
git clone <this repo> && cd threefinger
make install   # builds, copies binary, loads a launchd agent (autostart + keep-alive)
```

Installs to `/usr/local/bin` (or `~/.local/bin` if that's not writable) + `~/Library/LaunchAgents/com.firedev.threefinger.plist`. Re-running `make install` reinstalls cleanly.

## Permissions (read this)

The **binary itself** needs Accessibility — not your terminal. Under launchd there is no terminal to inherit from: if swipes seem detected but nothing happens, this is why.

System Settings → Privacy & Security → Accessibility → **+** → the installed `threefinger` binary. If touches don't register at all on recent macOS, add it under Input Monitoring too.

## Configure

The whole config is three constants at the top of `main.swift`:

```swift
let SWIPE_THRESHOLD: Float = 0.08                 // fraction of trackpad width
let KEY_SWIPE_LEFT: CGKeyCode = 123               // ← arrow
let KEY_SWIPE_RIGHT: CGKeyCode = 124              // → arrow
let MODIFIERS: CGEventFlags = [.maskCommand, .maskAlternate]  // ⌥⌘
```

Edit, `make install` again. Run `threefinger -v` in a terminal to watch swipes live while tuning.

## Caveats

- macOS's own 3-finger gestures (Mission Control, Space switching, three-finger drag) grab the same swipes. System Settings → Trackpad → More Gestures: set them to four fingers or off.
- Private Apple API — may break on a macOS update.

## Uninstall

```sh
make uninstall
```

## License

MIT
