import Cocoa

setbuf(stdout, nil) // -v output is tiny; unbuffered keeps it visible under redirection/launchd
let verbose = CommandLine.arguments.contains("-v") || CommandLine.arguments.contains("--verbose")
func log(_ s: String) { if verbose { print(s) } }
func err(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

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

if !AXIsProcessTrusted() {
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

guard let list = MTDeviceCreateList()?.takeUnretainedValue(), CFArrayGetCount(list) > 0 else {
    fatalError("no multitouch devices found (Input Monitoring permission missing?)")
}
for i in 0..<CFArrayGetCount(list) {
    let dev = UnsafeMutableRawPointer(mutating: CFArrayGetValueAtIndex(list, i))
    MTRegisterContactFrameCallback(dev, frameCallback)
    MTDeviceStart(dev, 0)
}
log("threefinger: watching \(CFArrayGetCount(list)) multitouch device(s)")
CFRunLoopRun()
