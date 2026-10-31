import AppKit
import SceneKit
import SwiftUI
import Metal

let widgetSize = CGSize(width: 310, height: 496)

final class BuddyModel: ObservableObject {
    @Published var snap = Snapshot()
    @Published var message = Banter.message(left: 1)
    @Published var prompt = Banter.prompt(left: 1)
    @Published var copied = false
    @Published var showSettings = false
    @Published var visibleSeconds = 15.0
    @Published var intervalMinutes = 30.0
    @Published var soundOn = true
    @Published var budget = 20.0
    @Published var themeName = "Aurora"
    var onHover: ((Bool) -> Void)?
    var onNewPrompt: (() -> Void)?
    var onCopy: (() -> Void)?
    var onToggleSettings: (() -> Void)?
    var onSettingsChanged: (() -> Void)?
}

struct SceneHost: NSViewRepresentable {
    let buddy: BuddyScene
    func makeNSView(context: Context) -> SCNView {
        let v = SCNView(); v.scene = buddy.scene; v.backgroundColor = .clear
        v.allowsCameraControl = false; v.antialiasingMode = .multisampling4X
        v.layer?.isOpaque = false; v.isPlaying = true; v.rendersContinuously = true
        return v
    }
    func updateNSView(_ v: SCNView, context: Context) {}
}

// MARK: - small custom controls (render in previews too, match the theme)
struct ThemeSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tint: Color
    let onEnd: () -> Void
    var body: some View {
        GeometryReader { g in
            let f = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.14)).frame(height: 8)
                Capsule().fill(tint).frame(width: max(8, g.size.width * f), height: 8)
                Circle().fill(Color.white).frame(width: 20, height: 20).shadow(radius: 2)
                    .offset(x: (g.size.width - 20) * f)
            }
            .frame(maxHeight: .infinity).contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    let k = min(max(v.location.x / g.size.width, 0), 1)
                    value = (range.lowerBound + k * (range.upperBound - range.lowerBound)).rounded()
                }
                .onEnded { _ in onEnd() })
        }.frame(height: 22)
    }
}

struct Chip: View {
    let title: String; let on: Bool; let tint: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 11, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity).padding(.vertical, 6)
                .background(Capsule().fill(on ? tint : Color.white.opacity(0.1)))
                .foregroundColor(on ? .black : .white)
        }.buttonStyle(.plain)
    }
}

/// Slowly drifting northern-lights glow with a few twinkling stars (Aurora theme).
struct AuroraGlow: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .top) {
                Ellipse().fill(Color(red: 0.2, green: 1, blue: 0.7)).frame(width: 300, height: 100)
                    .offset(x: 50 * sin(t * 0.35), y: 8 + 12 * sin(t * 0.6)).blur(radius: 28).opacity(0.7)
                Ellipse().fill(Color(red: 0.3, green: 0.45, blue: 1)).frame(width: 260, height: 90)
                    .offset(x: -60 * sin(t * 0.3 + 1), y: 55 + 12 * sin(t * 0.5 + 2)).blur(radius: 28).opacity(0.6)
                Ellipse().fill(Color(red: 0.55, green: 0.3, blue: 0.95)).frame(width: 220, height: 70)
                    .offset(x: 70 * sin(t * 0.25 + 3), y: 100 + 10 * sin(t * 0.45)).blur(radius: 26).opacity(0.45)
                ForEach(0..<16, id: \.self) { i in
                    let x = CGFloat((i * 53) % 270) - 135, y = CGFloat((i * 37) % 300)
                    Circle().fill(.white).frame(width: i % 3 == 0 ? 2.5 : 1.5).offset(x: x, y: y)
                        .opacity(0.35 + 0.35 * sin(t * (0.8 + Double(i) * 0.13) + Double(i)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct BuddyView: View {
    @ObservedObject var model: BuddyModel
    let sceneContent: AnyView

    var used: Double { model.snap.usedFraction }
    var left: Double { 1 - used }
    var theme: Theme { Theme.named(model.themeName) }
    var accent: Color { left <= 0 ? .gray : left < 0.2 ? Color(theme.low) : left < 0.4 ? Color(theme.mid) : Color(theme.good) }

    var body: some View {
        ZStack(alignment: .top) {
            Group { if model.showSettings { settingsCard } else { card } }.padding(.top, 118)
            RadialGradient(colors: [accent.opacity(0.38), accent.opacity(0.1), .clear], center: .center, startRadius: 5, endRadius: 125)
                .frame(width: 250, height: 250).padding(.top, -10).allowsHitTesting(false)   // soft stage glow behind the buddy
            sceneContent.frame(width: widgetSize.width, height: 215).allowsHitTesting(false)
            // tap the minion → settings
            Color.clear.frame(width: 150, height: 175).contentShape(Rectangle()).padding(.top, 20)
                .onTapGesture { model.onToggleSettings?() }
        }
        .frame(width: widgetSize.width, height: widgetSize.height, alignment: .top)
        .onHover { model.onHover?($0) }
    }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26)
            .fill(LinearGradient(colors: [Color(theme.cardTop), Color(theme.cardBottom)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
            .overlay { if theme.aurora { AuroraGlow().clipShape(RoundedRectangle(cornerRadius: 26)).allowsHitTesting(false) } }
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }

    var card: some View {
        VStack(spacing: 9) {
            Spacer().frame(height: 60)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.0f%%", left * 100))
                    .font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundColor(.white)
                Text("left today").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.6))
            }
            gauge
            Text(String(format: "used %.0f%%  ·  %@ tok  ·  %@", used * 100, tok(model.snap.tokens), model.snap.source))
                .font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.5)).lineLimit(1).minimumScaleFactor(0.8)

            Text(model.message)
                .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            Button { model.onCopy?() } label: {
                HStack(alignment: .top, spacing: 8) {
                    Text("💡").font(.system(size: 15))
                    Text(model.copied ? "Copied! Paste it into Claude ✨" : model.prompt)
                        .font(.system(size: 12, weight: .medium, design: .rounded)).italic()
                        .foregroundColor(.white.opacity(0.92)).multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(10).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(accent.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            }.buttonStyle(.plain)

            HStack {
                Button { model.onNewPrompt?() } label: {
                    Text("🎲 another idea").font(.system(size: 11, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                }.buttonStyle(.plain).foregroundColor(.white)
                Spacer()
                Text("tap idea to copy · tap me for ⚙️").font(.system(size: 9, design: .rounded)).foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 14)
        .frame(width: widgetSize.width - 16)
        .background(cardBackground)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    var settingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer().frame(height: 68)
            HStack {
                Text("⚙️ Buddy settings").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundColor(.white)
                Spacer()
                Button { model.onToggleSettings?() } label: {
                    Text("Done").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 5).background(Capsule().fill(accent))
                }.buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    label("Stay visible")
                    Spacer()
                    Text("\(Int(model.visibleSeconds)) sec").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(accent)
                }
                ThemeSlider(value: $model.visibleSeconds, range: 3...60, tint: accent) { model.onSettingsChanged?() }
                Text("minimum 3 sec · pauses while your mouse is on me").font(.system(size: 9, design: .rounded)).foregroundColor(.white.opacity(0.4))
            }
            VStack(alignment: .leading, spacing: 6) {
                label("Pop up every")
                HStack(spacing: 6) {
                    ForEach([(5.0, "5m"), (10, "10m"), (15, "15m"), (30, "30m"), (60, "1h")], id: \.0) { v, t in
                        Chip(title: t, on: model.intervalMinutes == v, tint: accent) { model.intervalMinutes = v; model.onSettingsChanged?() }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                label("Theme")
                HStack(spacing: 6) {
                    ForEach(Theme.all, id: \.name) { t in
                        Chip(title: t.name, on: model.themeName == t.name, tint: Color(t.good)) { model.themeName = t.name; model.onSettingsChanged?() }
                    }
                }
            }
            HStack {
                label("Sound")
                Spacer()
                Button { model.soundOn.toggle(); model.onSettingsChanged?() } label: {
                    ZStack(alignment: model.soundOn ? .trailing : .leading) {
                        Capsule().fill(model.soundOn ? accent : Color.white.opacity(0.18)).frame(width: 44, height: 24)
                        Circle().fill(.white).frame(width: 20, height: 20).padding(2)
                    }
                }.buttonStyle(.plain)
            }
            HStack {
                label("Daily budget")
                Spacer()
                stepButton("−") { model.budget = max(5, model.budget - 5); model.onSettingsChanged?() }
                Text(String(format: "$%.0f", model.budget)).font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white).frame(minWidth: 44)
                stepButton("+") { model.budget += 5; model.onSettingsChanged?() }
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 16)
        .frame(width: widgetSize.width - 16)
        .background(cardBackground)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    func label(_ t: String) -> some View {
        Text(t).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.8))
    }
    func stepButton(_ t: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t).font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(width: 26, height: 26)
                .background(Circle().fill(Color.white.opacity(0.14)))
        }.buttonStyle(.plain)
    }

    var gauge: some View {
        let frac = max(0.03, left)
        return GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule().fill(LinearGradient(colors: [accent.opacity(0.75), accent], startPoint: .leading, endPoint: .trailing))
                    .frame(width: g.size.width * frac)
                    .overlay(alignment: .top) {
                        Capsule().fill(Color.white.opacity(0.35)).frame(height: 4).padding(.horizontal, 6).padding(.top, 2)
                            .frame(width: g.size.width * frac)
                    }
            }
        }.frame(height: 14)
    }

    func tok(_ n: Int) -> String { n >= 1_000_000 ? String(format: "%.1fM", Double(n) / 1e6) : n >= 1000 ? "\(n / 1000)k" : "\(n)" }
}

// MARK: - preview rendering (no window needed)
@MainActor func renderSnapshot(to path: String, used: Double, settings: Bool) {
    let buddy = BuddyScene()
    let themeName = CommandLine.arguments.firstIndex(of: "--theme").map { CommandLine.arguments[$0 + 1] } ?? "Aurora"
    buddy.setTheme(Theme.named(themeName)); buddy.update(used: used)
    if CommandLine.arguments.contains("--shades") { buddy.previewShadesDown() }
    if CommandLine.arguments.contains("--walk") { buddy.previewWalk() }
    let r = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
    r.scene = buddy.scene; r.pointOfView = buddy.scene.rootNode.childNodes.first { $0.camera != nil }
    let img = r.snapshot(atTime: 0.5, with: CGSize(width: widgetSize.width * 2, height: 215 * 2), antialiasingMode: .multisampling4X)
    let model = BuddyModel()
    model.snap = Snapshot(tokens: 1_840_000, costUSD: 20 * used, apiCostUSD: nil, budgetUSD: 20)
    model.message = Banter.message(left: 1 - used); model.prompt = Banter.prompt(left: 1 - used)
    model.showSettings = settings; model.themeName = themeName
    let view = ZStack {
        LinearGradient(colors: [Color(red: 0.42, green: 0.46, blue: 0.52), Color(red: 0.26, green: 0.29, blue: 0.34)], startPoint: .top, endPoint: .bottom)
        BuddyView(model: model, sceneContent: AnyView(Image(nsImage: img).resizable().scaledToFit()))
    }.frame(width: widgetSize.width, height: widgetSize.height)
    let ir = ImageRenderer(content: view); ir.scale = 2
    guard let ns = ir.nsImage, let tiff = ns.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return }
    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
}

// MARK: - app
final class FloatingPanel: NSPanel { override var canBecomeKey: Bool { true } }

final class AppDelegate: NSObject, NSApplicationDelegate {
    var config = Config.load()
    let model = BuddyModel()
    let buddy = BuddyScene()
    let sound = Sound()
    var panel: NSPanel!
    var statusItem: NSStatusItem!
    var hideWork: DispatchWorkItem?
    var leaveWork: DispatchWorkItem?
    var hovering = false
    var leaving = false
    var stepTimer: Timer?

    func cancelHide() { hideWork?.cancel(); leaveWork?.cancel(); stepTimer?.invalidate() }
    var exitDir: CGFloat { config.corner.hasSuffix("Right") ? 1 : -1 }
    var intervalTimer: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        sound.enabled = config.sound
        model.visibleSeconds = config.visibleSeconds; model.intervalMinutes = config.intervalMinutes
        model.soundOn = config.sound; model.budget = config.dailyBudgetUSD
        model.themeName = config.theme; buddy.setTheme(Theme.named(config.theme))

        panel = FloatingPanel(contentRect: NSRect(origin: .zero, size: widgetSize), styleMask: [.borderless, .nonactivatingPanel],
                              backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = NSHostingView(rootView: BuddyView(model: model, sceneContent: AnyView(SceneHost(buddy: buddy))))
        panel.setFrame(frame(visible: false), display: false)
        panel.orderFrontRegardless()

        model.onHover = { [weak self] inside in
            guard let self else { return }
            // The window moving under a still cursor fires stray hover events, so trust only the real mouse position.
            let mouseIn = NSMouseInRect(NSEvent.mouseLocation, self.panel.frame, false)
            if inside && mouseIn {
                self.hovering = true
                self.cancelHide()
                if self.leaving { self.leaving = false; self.stepTimer?.invalidate(); self.buddy.resetWalk(); self.slide(visible: true, duration: 0.8) }   // came back while leaving
            } else if !inside && !mouseIn && self.hovering {
                self.hovering = false
                self.scheduleHide(after: max(self.config.visibleSeconds, 8))   // give it a proper stay again after you leave
            }
        }
        model.onNewPrompt = { [weak self] in
            guard let self else { return }
            self.model.prompt = Banter.prompt(left: 1 - self.model.snap.usedFraction); self.model.copied = false; self.sound.play(.pop)
        }
        model.onCopy = { [weak self] in
            guard let self else { return }
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(self.model.prompt, forType: .string)
            self.model.copied = true; self.sound.play(.copied)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.model.copied = false }
        }
        model.onToggleSettings = { [weak self] in
            guard let self else { return }
            self.model.showSettings.toggle(); self.sound.play(.pop)
            if self.model.showSettings { self.cancelHide() } else { self.scheduleHide(after: max(self.config.visibleSeconds, 8)) }
        }
        model.onSettingsChanged = { [weak self] in self?.applySettings() }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🍌"
        let menu = NSMenu()
        menu.addItem(withTitle: "Show now", action: #selector(showNow), keyEquivalent: "s").target = self
        menu.addItem(withTitle: "Hide", action: #selector(hideNow), keyEquivalent: "h").target = self
        menu.addItem(withTitle: "Edit config file…", action: #selector(editConfig), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        startIntervalTimer()
        showNow()
    }

    func startIntervalTimer() {
        intervalTimer?.invalidate()
        intervalTimer = Timer.scheduledTimer(withTimeInterval: config.intervalMinutes * 60, repeats: true) { [weak self] _ in self?.showNow() }
    }

    func applySettings() {
        config.visibleSeconds = max(3, model.visibleSeconds); config.intervalMinutes = model.intervalMinutes
        config.sound = model.soundOn; config.dailyBudgetUSD = model.budget; config.theme = model.themeName
        buddy.setTheme(Theme.named(model.themeName))
        config.save()
        sound.enabled = config.sound
        startIntervalTimer()
        model.snap.budgetUSD = config.dailyBudgetUSD
        buddy.update(used: model.snap.usedFraction)
        model.message = Banter.message(left: 1 - model.snap.usedFraction)
    }

    func frame(visible: Bool) -> NSRect {
        let s = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame, m: CGFloat = 10
        let right = config.corner.hasSuffix("Right"), top = config.corner.hasPrefix("top")
        let onX = right ? s.maxX - widgetSize.width - m : s.minX + m
        let offX = right ? s.maxX + 10 : s.minX - widgetSize.width - 10
        let y = top ? s.maxY - widgetSize.height - m : s.minY + m
        return NSRect(x: visible ? onX : offX, y: y, width: widgetSize.width, height: widgetSize.height)
    }

    /// Slow glide in (gentle overshoot); the exit is a steady, linear walking pace.
    func slide(visible: Bool, duration: Double = 1.8, walking: Bool = false) {
        if visible { leaving = false }
        NSAnimationContext.runAnimationGroup { c in
            c.duration = duration
            c.timingFunction = visible ? (walking ? CAMediaTimingFunction(controlPoints: 0.15, 0.55, 0.35, 1) : CAMediaTimingFunction(controlPoints: 0.25, 1.2, 0.35, 1)) : (walking ? CAMediaTimingFunction(name: .linear) : CAMediaTimingFunction(name: .easeInEaseOut))
            panel.animator().setFrame(frame(visible: visible), display: true)
        }
    }

    /// Soft footstep taps while walking.
    func startSteps(_ d: Double) {
        var steps = 0
        stepTimer?.invalidate()
        stepTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] t in
            steps += 1; self?.sound.play(.step)
            if steps >= Int(d / 0.45) { t.invalidate() }
        }
    }

    /// Wave goodbye, then walk off slowly with soft footsteps.
    func beginLeave() {
        leaving = true; buddy.goodbye(); sound.play(.hide)
        let out = DispatchWorkItem { [weak self] in
            guard let self, self.leaving else { return }
            let d = 6.0
            self.buddy.walkOut(dir: self.exitDir)
            self.slide(visible: false, duration: d, walking: true)
            self.startSteps(d)
        }
        leaveWork = out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: out)
    }

    func scheduleHide(after s: Double) {
        cancelHide()
        guard !model.showSettings else { return }
        let w = DispatchWorkItem { [weak self] in self?.beginLeave() }
        hideWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + max(3, s), execute: w)   // always stays at least 3 s
    }

    @objc func showNow() {
        cancelHide()
        Task { @MainActor in
            let s = await UsageReader.snapshot(budget: config.dailyBudgetUSD)
            let left = 1 - s.usedFraction
            model.snap = s; buddy.update(used: s.usedFraction)
            model.message = Banter.message(left: left); model.prompt = Banter.prompt(left: left); model.copied = false
            model.showSettings = false; leaving = false
            sound.play(left <= 0 ? .sad : .show)
            // walk in (mirror of the walk out), then turn to face you and start the nudge
            let d = 5.0
            buddy.walkIn(facing: -exitDir)
            slide(visible: true, duration: d, walking: true)
            startSteps(d)
            DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
                guard let self, !self.leaving else { return }
                self.buddy.stopWalk()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                    guard let self, !self.leaving else { return }
                    self.buddy.arrive(); if left >= 0.6 { self.sound.play(.nudge) }
                }
            }
            scheduleHide(after: config.visibleSeconds + d + 0.7)   // visible time counts from arrival
        }
    }
    @objc func hideNow() { cancelHide(); beginLeave() }
    @objc func editConfig() { NSWorkspace.shared.open(Config.url) }
}

let argv = CommandLine.arguments
if let i = argv.firstIndex(of: "--snapshot"), i + 2 < argv.count {
    MainActor.assumeIsolated {
        renderSnapshot(to: argv[i + 1], used: Double(argv[i + 2]) ?? 0.3, settings: argv.contains("--settings"))
    }
    exit(0)
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
