import AppKit
import SwiftUI

/// A complete colour story for the card, glow and every accessory.
struct Theme {
    let name: String
    let cardTop, cardBottom: NSColor          // card gradient
    let good, mid, low: NSColor               // budget tiers: plenty / getting low / nearly out
    let neon: NSColor                         // headphone rings, shade edge, rails, halo beads
    let thruster, laser: NSColor
    let cape, capeGlow, guitar, deck, band: NSColor
    let rim: NSColor                          // back rim light on the character
    var aurora = false                        // animated northern-lights glow on the card

    static func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor { NSColor(red: r, green: g, blue: b, alpha: 1) }

    static let all: [Theme] = [
        // Midnight teal + electric lime
        Theme(name: "Lime", cardTop: c(0.04, 0.16, 0.20), cardBottom: c(0.02, 0.07, 0.10),
              good: c(0.72, 1.0, 0.25), mid: c(1.0, 0.72, 0.12), low: c(1.0, 0.36, 0.22),
              neon: c(0.72, 1.0, 0.25), thruster: c(0.72, 1.0, 0.25), laser: c(0.85, 1.0, 1.0),
              cape: c(0.05, 0.30, 0.38), capeGlow: c(0.02, 0.14, 0.18), guitar: c(1.0, 0.45, 0.10), deck: c(0.05, 0.13, 0.17), band: c(0.72, 1.0, 0.25),
              rim: c(0.6, 1.0, 0.75)),
        // Warm charcoal + gold
        Theme(name: "Sunset", cardTop: c(0.20, 0.11, 0.07), cardBottom: c(0.10, 0.05, 0.04),
              good: c(1.0, 0.82, 0.20), mid: c(1.0, 0.55, 0.15), low: c(1.0, 0.30, 0.25),
              neon: c(1.0, 0.75, 0.20), thruster: c(1.0, 0.45, 0.10), laser: c(1.0, 0.95, 0.70),
              cape: c(0.62, 0.10, 0.12), capeGlow: c(0.22, 0.03, 0.03), guitar: c(0.10, 0.60, 0.75), deck: c(0.16, 0.09, 0.06), band: c(1.0, 0.75, 0.20),
              rim: c(1.0, 0.75, 0.45)),
        // Slate navy + ice
        Theme(name: "Arctic", cardTop: c(0.10, 0.15, 0.24), cardBottom: c(0.05, 0.08, 0.14),
              good: c(0.45, 0.85, 1.0), mid: c(1.0, 0.80, 0.30), low: c(1.0, 0.40, 0.35),
              neon: c(0.70, 0.95, 1.0), thruster: c(0.40, 0.80, 1.0), laser: c(1.0, 1.0, 1.0),
              cape: c(0.78, 0.90, 1.0), capeGlow: c(0.20, 0.28, 0.40), guitar: c(0.25, 0.45, 1.0), deck: c(0.14, 0.20, 0.30), band: c(0.85, 0.95, 1.0),
              rim: c(0.70, 0.85, 1.0)),
        // Black + terminal green
        Theme(name: "Retro", cardTop: c(0.02, 0.09, 0.05), cardBottom: c(0.0, 0.03, 0.02),
              good: c(0.20, 1.0, 0.40), mid: c(1.0, 0.80, 0.10), low: c(1.0, 0.30, 0.20),
              neon: c(0.20, 1.0, 0.40), thruster: c(0.20, 1.0, 0.40), laser: c(0.65, 1.0, 0.65),
              cape: c(0.05, 0.32, 0.12), capeGlow: c(0.0, 0.12, 0.04), guitar: c(1.0, 0.55, 0.10), deck: c(0.04, 0.10, 0.06), band: c(0.20, 1.0, 0.40),
              rim: c(0.50, 1.0, 0.60)),
        // Deep space + northern lights (animated)
        Theme(name: "Aurora", cardTop: c(0.03, 0.05, 0.14), cardBottom: c(0.0, 0.01, 0.06),
              good: c(0.30, 1.0, 0.78), mid: c(1.0, 0.80, 0.30), low: c(1.0, 0.38, 0.30),
              neon: c(0.40, 1.0, 0.92), thruster: c(0.30, 0.90, 1.0), laser: c(1.0, 1.0, 1.0),
              cape: c(0.28, 0.22, 0.80), capeGlow: c(0.06, 0.20, 0.42), guitar: c(0.15, 0.90, 0.70), deck: c(0.05, 0.07, 0.18), band: c(0.40, 1.0, 0.92),
              rim: c(0.55, 0.85, 1.0), aurora: true),
    ]
    static func named(_ n: String) -> Theme { all.first { $0.name == n } ?? all[0] }
}

extension Color { init(_ ns: NSColor) { self.init(nsColor: ns) } }
