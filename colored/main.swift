import AppKit

let color = NSColorSampler()

color.show { c in
    guard let c = c?.usingColorSpace(.deviceRGB) else { exit(0) }

    let r = Int(c.redComponent * 255)
    let g = Int(c.greenComponent * 255)
    let b = Int(c.blueComponent * 255)

    let hex = String(format: "%02X%02X%02X", r, g, b)

    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(hex, forType: .string)

    exit(0)
}

RunLoop.main.run()
