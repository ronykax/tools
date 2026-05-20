import AppKit
import ArgumentParser

// MARK: - Screen

func screenFrame() -> CGRect {
    NSScreen.main?.visibleFrame ?? .zero
}

// Accessibility API uses top-left origin; AppKit uses bottom-left.
// This converts an AppKit frame to the AX position.
func axOrigin(for cocoaFrame: CGRect) -> CGPoint {
    let primaryScreenHeight = NSScreen.screens[0].frame.height
    return CGPoint(
        x: cocoaFrame.minX,
        y: primaryScreenHeight - cocoaFrame.minY - cocoaFrame.height
    )
}

// MARK: - AX helpers

func focusedWindow() -> AXUIElement? {
    guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
    let axApp = AXUIElementCreateApplication(app.processIdentifier)
    var value: CFTypeRef?
    guard
        AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &value)
            == .success
    else {
        return nil
    }
    return (value as! AXUIElement)
}

func windowSize(of window: AXUIElement) -> CGSize {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &value) == .success,
        let axValue = value,
        AXValueGetType(axValue as! AXValue) == .cgSize
    else { return .zero }
    var size = CGSize.zero
    AXValueGetValue(axValue as! AXValue, .cgSize, &size)
    return size
}

func setPosition(_ window: AXUIElement, _ point: CGPoint) {
    var p = point
    if let axValue = AXValueCreate(.cgPoint, &p) {
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, axValue)
    }
}

func setSize(_ window: AXUIElement, _ size: CGSize) {
    var s = size
    if let axValue = AXValueCreate(.cgSize, &s) {
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, axValue)
    }
}

func applyFrame(_ window: AXUIElement, _ frame: CGRect) {
    setPosition(window, axOrigin(for: frame))
    setSize(window, frame.size)
}

// MARK: - Window actions

func centerWindow() {
    guard let window = focusedWindow() else { return }
    let screen = screenFrame()
    let size = windowSize(of: window)
    let origin = CGPoint(
        x: screen.minX + (screen.width - size.width) / 2,
        y: screen.minY + (screen.height - size.height) / 2
    )
    setPosition(window, axOrigin(for: CGRect(origin: origin, size: size)))
}

func maximizeWindow() {
    guard let window = focusedWindow() else { return }
    applyFrame(window, screenFrame())
}

func halfLeftWindow() {
    guard let window = focusedWindow() else { return }
    let screen = screenFrame()
    applyFrame(
        window,
        CGRect(x: screen.minX, y: screen.minY, width: screen.width / 2, height: screen.height))
}

func halfRightWindow() {
    guard let window = focusedWindow() else { return }
    let screen = screenFrame()
    applyFrame(
        window,
        CGRect(x: screen.midX, y: screen.minY, width: screen.width / 2, height: screen.height))
}

// MARK: - CLI

struct Window: ParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: [Center.self, Maximize.self, HalfLeft.self, HalfRight.self]
    )
}

struct Center: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Center the focused window on screen.")
    func run() { centerWindow() }
}

struct Maximize: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Maximize the focused window.")
    func run() { maximizeWindow() }
}

struct HalfLeft: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "half-left", abstract: "Snap the focused window to the left half.")
    func run() { halfLeftWindow() }
}

struct HalfRight: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "half-right", abstract: "Snap the focused window to the right half.")
    func run() { halfRightWindow() }
}

Window.main()
