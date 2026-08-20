import Cocoa

// ── config ─────────────────────────────────────────────────────────────
let SWIPE_THRESHOLD: Float = 0.08 // fraction of trackpad width; raise if too twitchy
let KEY_SWIPE_LEFT: CGKeyCode = 123 // ← arrow
let KEY_SWIPE_RIGHT: CGKeyCode = 124 // → arrow
let MODIFIERS: CGEventFlags = [.maskCommand, .maskAlternate] // ⌥⌘
// ───────────────────────────────────────────────────────────────────────

if !AXIsProcessTrusted() {
    print("No Accessibility permission — key events won't post. System Settings → Privacy & Security → Accessibility → add this binary (or your terminal), then restart it.")
}

func postKey(_ key: CGKeyCode) {
    let src = CGEventSource(stateID: .hidSystemState)
    for down in [true, false] {
        let e = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: down)
        e?.flags = MODIFIERS
        e?.post(tap: .cghidEventTap)
    }
}

// Gesture state. Frames for one device arrive on a single MT thread — no locking.
var acc: Float = 0
var prevX: Float?
var fired = false

let frameCallback: MTFrameCallbackFunction = { _, touches, n, _, _ in
    var xs: [Float] = []
    if let t = touches {
        for i in 0..<Int(n) where t[i].state == MTTouchState(MTTouchStateTouching) {
            xs.append(t[i].normalizedPosition.position.x)
        }
    }
    if xs.isEmpty { fired = false; prevX = nil; acc = 0; return } // fingers lifted → re-arm
    guard xs.count == 3 else { prevX = nil; acc = 0; return }     // not a 3-finger gesture
    let avg = (xs[0] + xs[1] + xs[2]) / 3
    if let p = prevX { acc += avg - p }
    prevX = avg
    if !fired && abs(acc) > SWIPE_THRESHOLD {
        fired = true // one action per swipe, until all fingers lift
        postKey(acc < 0 ? KEY_SWIPE_LEFT : KEY_SWIPE_RIGHT)
        print(acc < 0 ? "swipe left → key" : "swipe right → key")
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
print("threefinger: watching \(CFArrayGetCount(list)) multitouch device(s)")
CFRunLoopRun()
