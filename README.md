# threefinger

Three-finger horizontal swipe on the macOS trackpad → any keyboard shortcut. A tiny single-file replacement for that one BetterTouchTool feature. Default: swipe left posts ⌥⌘←, swipe right posts ⌥⌘→. One action per swipe; re-arms when all fingers lift.

![threefinger demo](demo.gif)

> ⚠️ macOS's own 3-finger gestures (Mission Control, Space switching, three-finger drag) grab the same swipes. System Settings → Trackpad → More Gestures: set them to four fingers or off.

**Why:** BetterTouchTool is paid, and nothing open source maps trackpad gestures to keyboard shortcuts. This does exactly that, in ~90 lines of Swift on the private `MultitouchSupport.framework`.

## Install

### Homebrew

```sh
brew install firedev/tap/threefinger
brew services start threefinger
```

### Installer script

Apple Silicon, no build tools needed:

```sh
curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/install.sh | bash
```

Downloads the latest [release](https://github.com/firedev/threefinger/releases) binary into `~/.local/bin`, installs `~/Library/LaunchAgents/com.firedev.threefinger.plist`, and loads the daemon (autostart + keep-alive). Re-running updates cleanly.

Don't download the release tar with a browser — the binary is ad-hoc signed, not notarized, and a browser download gets a Gatekeeper quarantine that blocks it. `curl`/`gh` downloads carry no quarantine.

### Build from source

```sh
git clone https://github.com/firedev/threefinger && cd threefinger
make install   # builds, copies binary, loads the launchd agent
```

Installs to `/usr/local/bin` (or `~/.local/bin` if that's not writable) + the same LaunchAgent. Re-running `make install` reinstalls cleanly.

## Permissions (read this)

The **binary itself** needs Accessibility — not your terminal. Under launchd there is no terminal to inherit from: if swipes seem detected but nothing happens, this is why.

System Settings → Privacy & Security → Accessibility → **+** → the installed `threefinger` binary. If touches don't register at all on recent macOS, add it under Input Monitoring too.

Accessibility is granted to the specific binary file: after an update replaces it, the grant can silently drop — swipes stop posting keys with no error. Re-grant in the same Settings pane.

## Configure

Config lives in `~/.config/threefinger.json`, Karabiner-style. Written with defaults on first run:

```json
{
  "description": "three-finger swipe → switch tabs",
  "manipulators": [
    {
      "from": { "gesture": "three_finger_swipe_left" },
      "to": [
        { "key_code": "left_arrow", "modifiers": ["left_command", "left_option"] }
      ],
      "type": "basic"
    },
    {
      "from": { "gesture": "three_finger_swipe_right" },
      "to": [
        { "key_code": "right_arrow", "modifiers": ["left_command", "left_option"] }
      ],
      "type": "basic"
    }
  ]
}
```

- **Gestures** (`from.gesture`): `three_finger_swipe_left` / `right` / `up` / `down`. Unmapped gestures do nothing.
- **`to`**: array of `{key_code, modifiers}`, posted in order. Karabiner key names: `a`–`z`, `0`–`9`, `left_arrow`/`right_arrow`/`up_arrow`/`down_arrow`, `return_or_enter`, `escape`, `tab`, `spacebar`, `delete_or_backspace`, `page_up`/`page_down`, `home`/`end`, `f1`–`f12`. Modifiers: `command`, `option`, `shift`, `control` (with or without `left_`/`right_` prefix — macOS posts them the same).
- **`threshold`**: optional top-level key, fraction of trackpad width (default `0.08`).

Config is read once at startup. After editing, restart the daemon:

```sh
launchctl kickstart -k gui/$UID/com.firedev.threefinger
```

Run `threefinger -v` in a terminal to watch gestures live while tuning (stop the daemon first, two instances double-fire).

### iTerm2

iTerm2 ships its own bindings on the same keys: ⌥⌘← is **Move Tab Left**, so a swipe drags the tab around instead of switching to it. Settings → Keys → Key Bindings: find the ⌥⌘←/⌥⌘→ entries and re-bind them to **Previous Tab** / **Next Tab** (or delete them — the swipe then falls through to the default tab switching).

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/uninstall.sh | bash
```

Or from a clone: `make uninstall`.

## License

MIT
