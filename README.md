# threefinger

Three-finger horizontal swipe on the macOS trackpad → any keyboard shortcut. A tiny single-file replacement for that one BetterTouchTool feature. Default: swipe left posts `Ctrl-Shift-Tab`, swipe right posts `Ctrl-Tab` (previous/next tab — works in Safari, Chrome, Firefox, and most tabbed apps). One action per swipe; re-arms when all fingers lift.

![threefinger demo](demo.gif)

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

## After install

The installer runs `threefinger --check --open`: prints permission status and opens the right System Settings panes (Accessibility / Input Monitoring if missing, plus **Trackpad → More Gestures**). macOS has no URL for that tab, so the binary opens Trackpad and selects More Gestures via Accessibility.

```sh
threefinger --check        # status only (exit 1 if anything missing)
threefinger --check --open # status + open the relevant Settings panes
```

1. **Permissions** — grant these to the **installed binary** (not your terminal):

   | Permission | Without it |
   | --- | --- |
   | Accessibility | Swipes are detected, but keys never post |
   | Input Monitoring | No multitouch devices show up |

   > After every upgrade the binary changes — remove the old entry (**−**), then re-add. Toggling the switch is not enough.

2. **Free the trackpad gesture** — macOS's own 3-finger ←/→ swipe grabs the same motion. With Accessibility granted, `--check --open` lands on **Trackpad → More Gestures**; set:

   | More Gestures | Set to |
   | --- | --- |
   | Swipe between pages | Off |
   | Swipe between full-screen applications | Swipe Left or Right with Four Fingers |

Then 3-finger swipe ←/→ to switch tabs (`Ctrl-Shift-Tab` / `Ctrl-Tab`).

**One daemon only.** Don’t run Homebrew and the curl/`make install` agent together — both fire on the same swipe and tabs look broken even when Accessibility is ok. `threefinger --check` warns if it sees more than one copy.

## Configure

Config lives in `~/.config/threefinger.json`, Karabiner-style. Written with defaults on first run:

```json
{
  "description": "three-finger swipe → switch tabs",
  "manipulators": [
    {
      "from": { "gesture": "three_finger_swipe_left" },
      "to": [
        { "key_code": "tab", "modifiers": ["left_control", "left_shift"] }
      ],
      "type": "basic"
    },
    {
      "from": { "gesture": "three_finger_swipe_right" },
      "to": [
        { "key_code": "tab", "modifiers": ["left_control"] }
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

Run `threefinger -v` in a terminal to watch gestures live while tuning (stop the daemon first — two instances double-fire).

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/uninstall.sh | bash
```

Or from a clone: `make uninstall`.

## License

MIT
