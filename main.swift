import Cocoa

setbuf(stdout, nil) // -v output is tiny; unbuffered keeps it visible under redirection/launchd
let verbose = CommandLine.arguments.contains("-v") || CommandLine.arguments.contains("--verbose")
func log(_ s: String) { if verbose { print(s) } }
func err(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

let VERSION = "1.1.7" // bump with the git tag at release

// A process launched from a terminal inherits the terminal's Accessibility
// grant, so --check asking AXIsProcessTrusted() about itself says "ok" while
// the daemon is denied. The daemon records what it actually got; --check reads it.
let STATUS_PATH = ("~/Library/Caches/threefinger.status" as NSString).expandingTildeInPath

// Anything unknown used to fall through and start a second daemon — swipes
// then double-fire and look broken.
let KNOWN_FLAGS: Set<String> = ["-v", "--verbose", "-c", "--check", "--open", "-V", "--version", "-h", "--help", "--reinstall"]
for arg in CommandLine.arguments.dropFirst() where !KNOWN_FLAGS.contains(arg) {
    err("threefinger: unknown option '\(arg)'")
    err("usage: threefinger [-v] [--check [--open]] [--reinstall] [--version]")
    exit(2)
}
if CommandLine.arguments.contains("--version") || CommandLine.arguments.contains("-V") {
    print("threefinger \(VERSION)")
    exit(0)
}
// The installer already stops every daemon (ours, both Homebrew labels) and
// bootstraps a fresh one — don't reimplement it here.
if CommandLine.arguments.contains("--reinstall") {
    let sh = Process()
    sh.executableURL = URL(fileURLWithPath: "/bin/bash")
    sh.arguments = ["-c", "curl -fsSL https://raw.githubusercontent.com/firedev/threefinger/master/install.sh | bash"]
    do { try sh.run() } catch { err("threefinger: \(error.localizedDescription)"); exit(1) }
    sh.waitUntilExit()
    exit(sh.terminationStatus)
}
if CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h") {
    print("""
    threefinger \(VERSION) — three-finger trackpad swipes → keyboard shortcuts

    usage: threefinger [-v] [--check [--open]] [--reinstall] [--version]

      -v, --verbose   log each gesture
      -c, --check     report permissions and daemon status (--open: open the panes)
      --reinstall     stop every daemon and install the latest release
      -V, --version   print version
      -h, --help      this

    config: ~/.config/threefinger.json
    """)
    exit(0)
}

let PREFS_AX = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
let PREFS_INPUT = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent"
let PREFS_TRACKPAD = "x-apple.systempreferences:com.apple.Trackpad-Settings.extension"

func openPrefs(_ url: String) {
    if let u = URL(string: url) { NSWorkspace.shared.open(u) }
}

/// Multitouch device count, or nil if MultitouchSupport can't be loaded.
func multitouchDeviceCount() -> Int? {
    guard let lib = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW) else { return nil }
    typealias CreateList = @convention(c) () -> Unmanaged<CFMutableArray>?
    guard let sym = dlsym(lib, "MTDeviceCreateList") else { return nil }
    let create = unsafeBitCast(sym, to: CreateList.self)
    guard let list = create()?.takeUnretainedValue() else { return 0 }
    return CFArrayGetCount(list)
}

// No URL anchor for the More Gestures tab — only trackpadTab exists — so open
// Trackpad settings and AX-press the tab (needs Accessibility on this binary).
func selectTrackpadMoreGesturesTab() -> Bool {
    func axAttr(_ el: AXUIElement, _ name: String) -> AnyObject? {
        var v: AnyObject?
        AXUIElementCopyAttributeValue(el, name as CFString, &v)
        return v
    }
    func axKids(_ el: AXUIElement) -> [AXUIElement] {
        (axAttr(el, kAXChildrenAttribute as String) as? [AXUIElement]) ?? []
    }
    func axRole(_ el: AXUIElement) -> String {
        (axAttr(el, kAXRoleAttribute as String) as? String) ?? ""
    }
    func axTitle(_ el: AXUIElement) -> String {
        (axAttr(el, kAXTitleAttribute as String) as? String)
            ?? (axAttr(el, kAXDescriptionAttribute as String) as? String)
            ?? ""
    }
    func pressMoreGestures(in root: AXUIElement) -> Bool {
        var q = [root]
        var i = 0
        while i < q.count && i < 3000 {
            let el = q[i]; i += 1
            if axRole(el) == kAXTabGroupRole as String {
                let radios = axKids(el).filter { axRole($0) == kAXRadioButtonRole as String }
                guard radios.count >= 3 else { q.append(contentsOf: axKids(el)); continue }
                // Prefer title match; fall back to 3rd tab (More Gestures) for other locales.
                let target = radios.first { axTitle($0) == "More Gestures" } ?? radios[2]
                return AXUIElementPerformAction(target, kAXPressAction as CFString) == .success
            }
            q.append(contentsOf: axKids(el))
        }
        return false
    }

    openPrefs(PREFS_TRACKPAD)
    let bundleIDs = ["com.apple.systempreferences", "com.apple.SystemSettings"]
    for _ in 0..<25 { // ~3s for System Settings to build the pane
        usleep(120_000)
        for id in bundleIDs {
            for app in NSRunningApplication.runningApplications(withBundleIdentifier: id) {
                if pressMoreGestures(in: AXUIElementCreateApplication(app.processIdentifier)) {
                    return true
                }
            }
        }
    }
    return false
}

// ── --check [--open]: permission status for installers / debugging ──────
if CommandLine.arguments.contains("--check") || CommandLine.arguments.contains("-c") {
    let doOpen = CommandLine.arguments.contains("--open")
    let bin = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath().path
    var ok = true

    print("Binary:           \(bin)")

    var daemonAX: Bool?
    if let rec = try? String(contentsOfFile: STATUS_PATH, encoding: .utf8) {
        let f = rec.split(separator: " ")
        if f.count >= 2, let pid = Int32(f[0]), kill(pid, 0) == 0 { daemonAX = f[1] == "1" }
    }
    let ax = daemonAX ?? AXIsProcessTrusted()
    let scope = daemonAX == nil ? " (no daemon record — checked this process)" : " (as the daemon sees it)"
    print("Accessibility:    \(ax ? "ok" : "MISSING — keys won't post")\(scope)")
    if !ax {
        ok = false
        print("  → Privacy & Security → Accessibility → + → \(bin)")
        print("    (after replace: remove (−) first; toggling is not enough)")
    }

    let n = multitouchDeviceCount()
    if let n, n > 0 {
        print("Input Monitoring: ok (\(n) multitouch device\(n == 1 ? "" : "s"))")
    } else {
        ok = false
        print("Input Monitoring: MISSING — no multitouch devices (or no trackpad)")
        print("  → Privacy & Security → Input Monitoring → + → \(bin)")
    }

    // Two daemons (e.g. brew services + make install) both fire on one swipe —
    // often looks like "Accessibility ok but tabs don't switch".
    let selfPID = ProcessInfo.processInfo.processIdentifier
    var daemons = [(pid: Int32, path: String)]()
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/ps")
    task.arguments = ["-axo", "pid=,command="]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    do {
        try task.run()
        // Read to EOF before/while process exits — wait-then-read deadlocks the pipe.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        let out = String(data: data, encoding: .utf8) ?? ""
        for line in out.split(separator: "\n") {
            let s = line.trimmingCharacters(in: .whitespaces)
            guard let sp = s.firstIndex(of: " ") else { continue }
            guard let pid = Int32(s[..<sp]), pid != selfPID else { continue }
            let cmd = String(s[s.index(after: sp)...])
            let path = cmd.split(separator: " ").first.map(String.init) ?? cmd
            // Exact binary name — ignore threefinger-check, shell lines, etc.
            guard URL(fileURLWithPath: path).lastPathComponent == "threefinger" else { continue }
            daemons.append((pid, path))
        }
    } catch {
        print("Daemon:           could not list processes (\(error.localizedDescription))")
    }
    if daemons.isEmpty {
        print("Daemon:           not running (start with: brew services start threefinger)")
        ok = false
    } else if daemons.count == 1 {
        print("Daemon:           ok (pid \(daemons[0].pid) — \(daemons[0].path))")
        let daemonReal = URL(fileURLWithPath: daemons[0].path).resolvingSymlinksInPath().path
        if daemonReal != bin {
            print("  ⚠ daemon path differs from this --check binary — grant Accessibility to the daemon path")
        }
    } else {
        ok = false
        print("Daemon:           \(daemons.count) copies running — swipes double-fire and look broken")
        for d in daemons { print("  pid \(d.pid)  \(d.path)") }
        print("  → keep one installer only (brew XOR curl/make install), stop the other")
    }

    if doOpen {
        let needInput = n == nil || n == 0
        // Opening Trackpad first steals System Settings away from Privacy panes
        // (async). If grants are missing, open those and stop — re-run for gestures.
        if !ax || needInput {
            if needInput {
                openPrefs(PREFS_INPUT)
                usleep(300_000)
            }
            if !ax {
                openPrefs(PREFS_AX)
                // Fallback deep link used on older macOS builds.
                usleep(200_000)
                openPrefs("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            }
            var parts = [String]()
            if !ax { parts.append("Accessibility") }
            if needInput { parts.append("Input Monitoring") }
            print("Opened \(parts.joined(separator: " + ")) — grant \(bin), then re-run --check --open for More Gestures")
        } else {
            let tabbed = selectTrackpadMoreGesturesTab()
            print(tabbed
                ? "Opened Trackpad → More Gestures"
                : "Opened Trackpad (couldn’t select More Gestures)")
        }
    }
    exit(ok ? 0 : 1)
}

// ── config: ~/.config/threefinger.json, Karabiner-style ────────────────
// Written verbatim as the default config — literal template keeps key order
// and 2-space indent exactly as Karabiner users expect.
let DEFAULT_CONFIG = """
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
"""

struct Config: Codable { var threshold: Float?; var manipulators: [Manipulator] }
struct Manipulator: Codable { var from: From; var to: [To] }
struct From: Codable { var gesture: String }
struct To: Codable { var key_code: String; var modifiers: [String]? }

let configURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/threefinger.json")
if !FileManager.default.fileExists(atPath: configURL.path) {
    try? FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    do {
        try DEFAULT_CONFIG.write(to: configURL, atomically: true, encoding: .utf8)
        err("threefinger: wrote default config to \(configURL.path)")
    } catch { err("threefinger: cannot write \(configURL.path): \(error.localizedDescription)") }
}
let config: Config = {
    if let data = try? Data(contentsOf: configURL), let c = try? JSONDecoder().decode(Config.self, from: data) { return c }
    err("threefinger: cannot parse \(configURL.path) — using built-in defaults")
    return try! JSONDecoder().decode(Config.self, from: DEFAULT_CONFIG.data(using: .utf8)!)
}()
let threshold = config.threshold ?? 0.08 // fraction of trackpad width

// Karabiner key_code names → macOS virtual keycodes (ANSI layout, kVK_*)
let KEY_CODES: [String: CGKeyCode] = [
    "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
    "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "o": 31, "u": 32,
    "i": 34, "p": 35, "l": 37, "j": 38, "k": 40, "n": 45, "m": 46,
    "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25, "0": 29,
    "return_or_enter": 36, "escape": 53, "tab": 48, "spacebar": 49, "delete_or_backspace": 51,
    "left_arrow": 123, "right_arrow": 124, "down_arrow": 125, "up_arrow": 126,
    "page_up": 116, "page_down": 121, "home": 115, "end": 119,
    "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97, "f7": 98, "f8": 100,
    "f9": 101, "f10": 109, "f11": 103, "f12": 111,
]
// CGEventFlags can't distinguish left/right, so "left_command" == "command"
let MOD_FLAGS: [String: CGEventFlags] = [
    "command": .maskCommand, "option": .maskAlternate, "shift": .maskShift, "control": .maskControl,
]
let GESTURES = ["three_finger_swipe_left", "three_finger_swipe_right", "three_finger_swipe_up", "three_finger_swipe_down"]

var actions: [String: [(key: CGKeyCode, flags: CGEventFlags)]] = [:]
for m in config.manipulators {
    guard GESTURES.contains(m.from.gesture) else { err("threefinger: unknown gesture '\(m.from.gesture)' — skipping manipulator"); continue }
    var seq = [(key: CGKeyCode, flags: CGEventFlags)]()
    var bad: String?
    outer: for t in m.to {
        guard let key = KEY_CODES[t.key_code] else { bad = "key_code '\(t.key_code)'"; break }
        var flags = CGEventFlags()
        for mod in t.modifiers ?? [] {
            var base = mod
            for p in ["left_", "right_"] where base.hasPrefix(p) { base = String(base.dropFirst(p.count)) }
            guard let f = MOD_FLAGS[base] else { bad = "modifier '\(mod)'"; break outer }
            flags.insert(f)
        }
        seq.append((key, flags))
    }
    if let b = bad { err("threefinger: unknown \(b) in '\(m.from.gesture)' — skipping manipulator"); continue }
    actions[m.from.gesture] = seq
}
if actions.isEmpty { err("threefinger: no usable manipulators in \(configURL.path)") }
log("threefinger: \(actions.count) gesture(s) mapped, threshold \(threshold)")

// Prompt, don't just report: the system dialog registers THIS binary's code
// identity. Adding the path by hand re-uses a stale entry after every upgrade
// and stays silently denied.
let axTrusted = AXIsProcessTrustedWithOptions(
    [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
// What --check reports — written before the first swipe can fail silently.
try? "\(ProcessInfo.processInfo.processIdentifier) \(axTrusted ? 1 : 0)\n"
    .write(toFile: STATUS_PATH, atomically: true, encoding: .utf8)
if !axTrusted {
    err("No Accessibility permission — key events won't post. System Settings → Privacy & Security → Accessibility → add this binary, then restart it.")
}

func fire(_ gesture: String) {
    guard let seq = actions[gesture] else { return } // unmapped gesture: fire nothing
    let src = CGEventSource(stateID: .hidSystemState)
    for (key, flags) in seq {
        for down in [true, false] {
            let e = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: down)
            e?.flags = flags
            e?.post(tap: .cghidEventTap)
        }
    }
    log("gesture: \(gesture)")
}

// Gesture state. Frames for one device arrive on a single MT thread — no locking.
var accX: Float = 0
var accY: Float = 0
var prev: (x: Float, y: Float)?
var fired = false

let frameCallback: MTFrameCallbackFunction = { _, touches, n, _, _ in
    var xs = [Float](), ys = [Float]()
    if let t = touches {
        for i in 0..<Int(n) where t[i].state == MTTouchState(MTTouchStateTouching) {
            xs.append(t[i].normalizedPosition.position.x)
            ys.append(t[i].normalizedPosition.position.y)
        }
    }
    if xs.isEmpty { fired = false; prev = nil; accX = 0; accY = 0; return } // fingers lifted → re-arm
    guard xs.count == 3 else { prev = nil; accX = 0; accY = 0; return }     // not a 3-finger gesture
    let ax = (xs[0] + xs[1] + xs[2]) / 3, ay = (ys[0] + ys[1] + ys[2]) / 3
    if let p = prev { accX += ax - p.x; accY += ay - p.y }
    prev = (ax, ay)
    if !fired { // one action per swipe, until all fingers lift
        if abs(accX) > threshold {
            fired = true; fire(accX < 0 ? "three_finger_swipe_left" : "three_finger_swipe_right")
        } else if abs(accY) > threshold { // normalized y grows upward
            fired = true; fire(accY < 0 ? "three_finger_swipe_down" : "three_finger_swipe_up")
        }
    }
}

// The private framework's binary is in the dyld shared cache — dlopen by path
// still works, and dlsym avoids linking against it at build time.
guard let lib = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW) else {
    fatalError("dlopen MultitouchSupport failed")
}
func sym<T>(_ name: String, _ type: T.Type) -> T {
    guard let p = dlsym(lib, name) else { fatalError("dlsym \(name) failed") }
    return unsafeBitCast(p, to: T.self)
}
let MTDeviceCreateList = sym("MTDeviceCreateList", (@convention(c) () -> Unmanaged<CFMutableArray>?).self)
let MTRegisterContactFrameCallback = sym("MTRegisterContactFrameCallback", (@convention(c) (MTDeviceRef?, MTFrameCallbackFunction?) -> Void).self)
let MTDeviceStart = sym("MTDeviceStart", (@convention(c) (MTDeviceRef?, Int32) -> Void).self)
let MTDeviceStop = sym("MTDeviceStop", (@convention(c) (MTDeviceRef?) -> Void).self)

// Devices registered before a sleep stop delivering frames after wake — the
// process stays alive and silently does nothing. Re-register on every wake.
var devices = [MTDeviceRef?]()
func watchDevices() {
    for dev in devices { MTDeviceStop(dev) }
    devices = []
    guard let list = MTDeviceCreateList()?.takeUnretainedValue(), CFArrayGetCount(list) > 0 else { return }
    for i in 0..<CFArrayGetCount(list) {
        let dev = UnsafeMutableRawPointer(mutating: CFArrayGetValueAtIndex(list, i))
        MTRegisterContactFrameCallback(dev, frameCallback)
        MTDeviceStart(dev, 0)
        devices.append(dev)
    }
    log("threefinger: watching \(devices.count) multitouch device(s)")
}

watchDevices()
if devices.isEmpty {
    fatalError("no multitouch devices found (Input Monitoring permission missing?)")
}
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
) { _ in watchDevices() }
CFRunLoopRun()
