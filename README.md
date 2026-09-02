# threefinger

Three-finger swipe on the Mac trackpad → switch tabs. Or the shortcut of your choice.

Default left/right posts `Ctrl-Shift-Tab` / `Ctrl-Tab`. Pair with Mission Control and App Exposé on three-finger up/down for a full set — all windows, this app’s windows, previous tab, next tab. Tiny open-source Swift tool; one action per swipe, re-arms when fingers lift.

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

Two quick things, then swipe:

1. **Let threefinger work.** macOS blocks background apps from reading the trackpad and typing keys until you allow it. Run:

   ```sh
   threefinger --check --open
   ```

   Turn on **Accessibility** and **Input Monitoring** for `threefinger` when Settings asks (or opens those panes). Not for Terminal — for threefinger itself.

2. **Give the swipe back.** macOS uses the same three-finger ←/→ for Spaces. In **Trackpad → More Gestures** set **Swipe between full-screen applications** to **Swipe Left or Right with Four Fingers**.  
   **Swipe between pages → Off** is optional, but nicer if Safari also grabs the gesture.

Leave **Mission Control** and **App Exposé** on three fingers. Then you get a clean set:

| Three fingers | Does |
| --- | --- |
| ↑ | All windows (Mission Control) |
| ↓ | Windows for this app (App Exposé) |
| ← | Previous tab |
| → | Next tab |

<details>
<summary>Paths, upgrades, troubleshooting</summary>

| Permission | Without it |
| --- | --- |
| Accessibility | Swipes detected, keys never post |
| Input Monitoring | No trackpad devices seen |

Add the binary via **+** → **Cmd-Shift-G** → paste path → **Open** → enable:

| Install | Path |
| --- | --- |
| Homebrew | `/opt/homebrew/opt/threefinger/bin/threefinger` |
| curl installer | `~/.local/bin/threefinger` |

After every upgrade the binary changes — remove the old entry (**−**), then re-add. Toggling the switch is not enough.

Don’t run Homebrew and the curl/`make install` agent together — both fire on one swipe and tabs look broken. `threefinger --check` warns if it sees more than one copy.

`threefinger --check` — status only (exit 1 if anything missing).

</details>

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
