# threefinger

Swipe with three fingers on the Mac trackpad to change tabs.

Left/right posts `Ctrl-Shift-Tab` / `Ctrl-Tab`. Works in Safari, Chrome, Firefox, and most tabbed apps.

![threefinger demo](demo.gif)

Keep **Mission Control** and **App Exposé** on three fingers and you get a full set:

| Three fingers | Does |
| --- | --- |
| ← / → | Previous / next tab |
| ↑ | All windows |
| ↓ | Windows for this app |

## Setup

1. Install and allow threefinger when Settings asks (Accessibility + Input Monitoring — for threefinger, not Terminal):

   ```sh
   curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/install.sh | bash
   threefinger --check --open
   ```

   Or: `brew install firedev/tap/threefinger && brew services start threefinger`

2. In **Trackpad → More Gestures**, set **Swipe between full-screen applications** to **Swipe Left or Right with Four Fingers** so macOS doesn’t steal the horizontal swipe. **Swipe between pages → Off** is optional.

Then swipe.

More: [firedev.com/projects/threefinger](https://firedev.com/projects/threefinger/)

<details>
<summary>Config, build, uninstall</summary>

Config: `~/.config/threefinger.json` (Karabiner-style). Defaults map left/right to tab switching. Any shortcut works. Restart after edits:

```sh
brew services restart threefinger
# or
launchctl kickstart -k gui/$UID/com.firedev.threefinger
```

Build from source: `git clone https://github.com/firedev/threefinger && cd threefinger && make install`

Uninstall: `curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/uninstall.sh | bash` or `make uninstall` / `brew uninstall threefinger`

Don’t run Homebrew and the curl installer together — two daemons double-fire. After upgrades, remove (−) and re-add Accessibility for the new binary.

Open source, MIT. Tiny Swift tool on MultitouchSupport — a one-feature BetterTouchTool replacement.

</details>
