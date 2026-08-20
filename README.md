# threefinger

Three-finger horizontal swipe on the trackpad → keyboard shortcut. Swipe left posts ⌥⌘← , swipe right posts ⌥⌘→ . One action per swipe; re-arms when all fingers lift. Uses the private `MultitouchSupport.framework`.

Threshold and key mappings are constants at the top of `main.swift` — that's the whole config.

## Build & run

```
make        # → ./threefinger
make run
```

## Permissions

- **Accessibility** (to post key events): System Settings → Privacy & Security → Accessibility → add the binary or the terminal you run it from. The tool prints a warning at startup if missing.
- **Input Monitoring** may be needed on recent macOS for reading trackpad contacts — add it there too if no swipes register.

## Caveats

- macOS's own 3-finger gestures (Mission Control / Space switching / three-finger drag) grab the same swipes. Set System Settings → Trackpad → More Gestures to four fingers or off for the ones you keep.
- Private API — could break on any macOS update.

## Run at login

Wrap it in a launchd user agent (`~/Library/LaunchAgents/*.plist` with `KeepAlive`) — left as an exercise until it's proven useful.
