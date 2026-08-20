# threefinger

Three-finger horizontal swipe on the macOS trackpad → any keyboard shortcut. A tiny single-file replacement for that one BetterTouchTool feature. Default: swipe left posts ⌥⌘←, swipe right posts ⌥⌘→. One action per swipe; re-arms when all fingers lift.

**Why:** BetterTouchTool is paid, and nothing open source maps trackpad gestures to keyboard shortcuts. This does exactly that, in ~90 lines of Swift on the private `MultitouchSupport.framework`.

## Install

```sh
git clone <this repo> && cd threefinger
make install   # builds, copies binary, loads a launchd agent (autostart + keep-alive)
```

Or grab a prebuilt universal binary from [Releases](https://github.com/firedev/threefinger/releases) — it's ad-hoc signed, so clear quarantine after download:

```sh
tar xzf threefinger-*.tar.gz
xattr -d com.apple.quarantine threefinger 2>/dev/null; ./threefinger -v
```

For autostart still clone the repo and run `make install` (it wires up the launchd agent).

Installs to `/usr/local/bin` (or `~/.local/bin` if that's not writable) + `~/Library/LaunchAgents/com.firedev.threefinger.plist`. Re-running `make install` reinstalls cleanly.

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

## Caveats

- macOS's own 3-finger gestures (Mission Control, Space switching, three-finger drag) grab the same swipes. System Settings → Trackpad → More Gestures: set them to four fingers or off.
- Private Apple API — may break on a macOS update.

## Uninstall

```sh
make uninstall
```

## License

MIT
