# threefinger

> **Get 1.1.5 or newer** — earlier versions stopped swiping after the Mac slept. `threefinger --version` to check, `threefinger --reinstall` to update.

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

## Update / repair

```sh
threefinger --reinstall
```

Stops every copy (curl or Homebrew), installs the latest release, re-checks permissions. Re-running the curl one-liner from Setup does the same thing — both are safe to run over an existing install.

Switching from Homebrew to the curl install (one daemon, no rebuild on upgrade):

```sh
brew uninstall threefinger
curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/install.sh | bash
```

## Config

Edit `~/.config/threefinger.json` (Karabiner-style). By default, left/right change tabs; you can map any shortcut. Restart after editing:

```sh
brew services restart threefinger
# or, if you used the curl installer:
launchctl kickstart -k gui/$UID/com.firedev.threefinger
```

## Build from source

```sh
git clone https://github.com/firedev/threefinger && cd threefinger
make install
```

## Uninstall

```sh
# curl install
curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/uninstall.sh | bash

# Homebrew
brew uninstall threefinger

# from a clone
make uninstall
```

> Use **either** Homebrew **or** the curl installer — not both. Two daemons will fight over the same swipe.

> After every upgrade, remove threefinger from Accessibility (**−**) and add the new binary again, then restart the service. Toggling the switch is not enough — and a grant does not apply to a daemon that is already running.

## License

MIT. Tiny Swift tool on MultitouchSupport — a one-feature BetterTouchTool replacement.
