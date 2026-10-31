import AppKit
import SceneKit

enum Mood { case eager, happy, nervous, worried, sleepy }   // eager = lots of budget left: friendly but pushy, never celebrating

/// Glossy 3D minion-style buddy with a Claude-coral strap and a Claude spark on the overalls.
/// Mood follows how much of the daily budget is used.
final class BuddyScene {
    let scene = SCNScene()
    private let root = SCNNode()
    private let eyeL = SCNNode(), eyeR = SCNNode()
    private var pupils: [SCNNode] = []
    private var whites: [SCNMaterial] = []
    private let mouth = SCNNode()
    private let armR = SCNNode(), armL = SCNNode()
    private let sweat = SCNNode()
    private let sparkNode = SCNNode()
    private let zzz = SCNNode()
    private let propHold = SCNNode(), battery = SCNNode(), mug = SCNNode(), sparkles = SCNNode(), steam = SCNNode()
    private let fillNode = SCNNode(), fillMat = SCNMaterial()
    private var armLBase: CGFloat = -1.5708
    private let shades = SCNNode(), orbit = SCNNode()
    private var beads: [SCNNode] = []
    private let beadMat = SCNMaterial()
    private var coolMode = false
    private let cape = SCNNode(), board = SCNNode(), guitar = SCNNode(), scan = SCNNode(), shadowNode = SCNNode()
    private var boots: [SCNNode] = []
    private let flames = SCNNode()
    private var wink = false
    private var guitarMode = false
    private var armRBase: CGFloat = 1.5708
    private var timers: [Timer] = []

    private let yellow = NSColor(red: 0.98, green: 0.62, blue: 0.16, alpha: 1)   // amber (Claude buddy body)
    private let denim = NSColor(red: 0.10, green: 0.24, blue: 0.62, alpha: 1)
    private let claudeCoral = NSColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1)   // Claude brand coral
    private let amber = NSColor(red: 1.0, green: 0.62, blue: 0.10, alpha: 1)
    private let neonMat = SCNMaterial(), railMat = SCNMaterial(), thrustMat = SCNMaterial(), coneMat = SCNMaterial(), scanMat = SCNMaterial()
    private let capeMat = SCNMaterial(), guitarMat = SCNMaterial(), deckMat = SCNMaterial(), bandMat = SCNMaterial()
    private var theme = Theme.named("Aurora")
    private var lastMood: Mood = .happy
    private var lastLeft = 0.5
    private var rimNode = SCNNode()
    private let claudeCream = NSColor(red: 0.96, green: 0.93, blue: 0.87, alpha: 1)

    init() {
        scene.background.contents = NSColor.clear
        scene.lightingEnvironment.contents = Self.envImage()
        scene.lightingEnvironment.intensity = 1.3

        let cam = SCNNode(); cam.camera = SCNCamera(); cam.camera!.fieldOfView = 30
        cam.camera!.wantsHDR = true; cam.camera!.bloomIntensity = 0.7; cam.camera!.bloomThreshold = 0.85; cam.camera!.bloomBlurRadius = 8
        cam.position = SCNVector3(0, -0.35, 9.0); scene.rootNode.addChildNode(cam)
        let key = SCNNode(); key.light = SCNLight(); key.light!.type = .directional; key.light!.intensity = 900
        key.eulerAngles = SCNVector3(-0.6, 0.5, 0); scene.rootNode.addChildNode(key)
        let rim = SCNNode(); rim.light = SCNLight(); rim.light!.type = .directional; rim.light!.intensity = 900
        rim.light!.color = NSColor(red: 0.65, green: 0.55, blue: 1, alpha: 1)
        rim.eulerAngles = SCNVector3(-0.2, -2.4, 0); scene.rootNode.addChildNode(rim); rimNode = rim

        buildShadow(); buildBody(); buildHead(); buildGoggles(); buildMouth(); buildLimbs(); buildHair(); buildProps(); buildCool(); buildExtras()
        scene.rootNode.addChildNode(root)
        setMood(.happy); applyProps(.happy, left: 0.5)
        setTheme(Theme.named("Aurora"))

        let two = CGFloat.pi * 2
        root.runAction(.repeatForever(.customAction(duration: 2) { n, t in
            let s = sin(t / 2 * two)
            n.scale = SCNVector3(1 - 0.02 * s, 1 + 0.035 * s, 1 - 0.02 * s)
            n.position.y = 0.05 * s
        }))
        sparkNode.runAction(.repeatForever(.rotateBy(x: 0, y: 0, z: -.pi * 2, duration: 14)))
        timers.append(Timer.scheduledTimer(withTimeInterval: 3.1, repeats: true) { [weak self] _ in self?.blink() })
        timers.append(Timer.scheduledTimer(withTimeInterval: 2.3, repeats: true) { [weak self] _ in self?.look() })
        timers.append(Timer.scheduledTimer(withTimeInterval: 7, repeats: true) { [weak self] _ in self?.wave() })
    }

    // MARK: building
    /// Prepare a theme-driven material (its colour is set in setTheme).
    private func styled(_ m: SCNMaterial, rough: CGFloat, metal: CGFloat = 0) -> SCNMaterial {
        m.lightingModel = .physicallyBased; m.roughness.contents = rough; m.metalness.contents = metal; return m
    }
    private func mat(_ c: NSColor, rough: CGFloat = 0.35, metal: CGFloat = 0, emissive: Bool = false) -> SCNMaterial {
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        m.diffuse.contents = c; m.roughness.contents = rough; m.metalness.contents = metal
        if emissive { m.emission.contents = c }
        return m
    }
    private func sphere(_ r: CGFloat, _ m: SCNMaterial, scale: SCNVector3 = SCNVector3(1, 1, 1), at p: SCNVector3) -> SCNNode {
        let g = SCNSphere(radius: r); g.segmentCount = 48; g.materials = [m]
        let n = SCNNode(geometry: g); n.scale = scale; n.position = p; return n
    }

    private func buildShadow() {
        let c = SCNCylinder(radius: 0.95, height: 0.01)
        let m = SCNMaterial(); m.lightingModel = .constant; m.diffuse.contents = NSColor.black.withAlphaComponent(0.28)
        c.materials = [m]
        shadowNode.geometry = c; shadowNode.position = SCNVector3(0, -1.4, 0.1); shadowNode.scale = SCNVector3(1, 1, 0.55)
        scene.rootNode.addChildNode(shadowNode)
    }

    // MARK: Clawd - the Claude Code mascot as a glossy 3D pixel character (12x8 sprite, 8-wide torso,
    // side bumps as arms, four legs, two black square eyes, no mouth). Body colour #DA7758.
    private let u: CGFloat = 0.24
    private let clawdColor = NSColor(red: 0.855, green: 0.467, blue: 0.345, alpha: 1)   // #DA7758
    private var bootBase: [SCNVector3] = []
    private var asleep = false
    private func cx(_ c: Int) -> CGFloat { (CGFloat(c) - 5.5) * u }
    private func cy(_ r: Int) -> CGFloat { -1.23 + CGFloat(7 - r) * u }

    /// Keeps the true #DA7758 on screen (PBR + bright environment washed it out to pink).
    private func clawdMat() -> SCNMaterial {
        let m = SCNMaterial(); m.lightingModel = .blinn
        // diffuse is nudged up so the *lit* front face renders as #DA7758 (measured: 195,118,89 -> 218,119,88)
        let lit = NSColor(red: 0.956, green: 0.471, blue: 0.341, alpha: 1)
        m.diffuse.contents = lit; m.ambient.contents = clawdColor
        m.specular.contents = NSColor(white: 0.28, alpha: 1); m.shininess = 0.35
        return m
    }

    private func buildBody() {
        let m = clawdMat()
        let torso = SCNBox(width: u * 8, height: u * 6, length: u * 3, chamferRadius: 0.05); torso.materials = [m]   // one smooth block, like the icon
        let tn = SCNNode(geometry: torso); tn.position = SCNVector3(0, (cy(0) + cy(5)) / 2, 0); root.addChildNode(tn)
        for c in [2, 4, 7, 9] {                // four legs, two cells tall
            let box = SCNBox(width: u * 0.975, height: u * 2 * 0.975, length: u * 2.7, chamferRadius: 0.035); box.materials = [m]
            let n = SCNNode(geometry: box); n.position = SCNVector3(cx(c), (cy(6) + cy(7)) / 2, 0)
            boots.append(n); bootBase.append(n.position); root.addChildNode(n)
        }
    }

    private func buildHead() {}

    private func buildGoggles() {   // the two black square eyes
        for (i, c) in [3, 8].enumerated() {
            let eye = i == 0 ? eyeL : eyeR
            eye.position = SCNVector3(cx(c), cy(1), u * 1.5 + 0.012)
            let inner = SCNNode()
            let g = SCNBox(width: u * 0.9, height: u * 1.1, length: 0.05, chamferRadius: 0.02); g.materials = [mat(.black, rough: 0.12)]
            inner.geometry = g
            eye.addChildNode(inner); pupils.append(inner)
            root.addChildNode(eye)
        }
        sweat.addChildNode(sphere(0.09, mat(NSColor.cyan, rough: 0.1, emissive: true), scale: SCNVector3(1, 1.5, 0.7), at: SCNVector3(0, 0, 0)))
        sweat.position = SCNVector3(0.95, 0.62, 0.45); sweat.isHidden = true
        sweat.runAction(.repeatForever(.sequence([.moveBy(x: 0, y: -0.4, z: 0, duration: 0.9), .moveBy(x: 0, y: 0.4, z: 0, duration: 0)])))
        root.addChildNode(sweat)
    }

    private func buildMouth() {}   // Clawd has no mouth

    private func buildLimbs() {    // the side bumps are the arms: 2x2 blocks that pivot at the body edge
        let m = clawdMat()
        for (arm, sign) in [(armL, CGFloat(-1)), (armR, CGFloat(1))] {
            let box = SCNBox(width: u * 2 * 0.975, height: u * 2 * 0.975, length: u * 2.7, chamferRadius: 0.035); box.materials = [m]
            let g = SCNNode(geometry: box); g.position = SCNVector3(0, -u, 0)
            arm.addChildNode(g)
            arm.position = SCNVector3(sign * 4 * u, (cy(2) + cy(3)) / 2, 0); arm.eulerAngles.z = sign * 1.5708
            root.addChildNode(arm)
        }
    }

    private func buildHair() {}

    /// Claude-style spark: coral rays of varied length radiating from a centre, on a cream pocket patch.
    private func buildSpark() {
        let patch = SCNCylinder(radius: 0.24, height: 0.04); patch.materials = [mat(claudeCream, rough: 0.5)]
        let pn = SCNNode(geometry: patch); pn.eulerAngles.x = .pi / 2; pn.position = SCNVector3(0, -0.46, 0.815)
        root.addChildNode(pn)

        let lens: [CGFloat] = [1, 0.8, 0.95, 0.72, 1, 0.84, 0.94, 0.76, 1, 0.82, 0.92, 0.78]
        let sm = mat(claudeCoral, rough: 0.4, emissive: true); sm.emission.intensity = 0.25
        for (i, l) in lens.enumerated() {
            let c = SCNCapsule(capRadius: 0.018, height: 0.17 * l * 2 / 2 + 0.036); c.materials = [sm]
            let n = SCNNode(geometry: c)
            n.pivot = SCNMatrix4MakeTranslation(0, -(c.height / 2), 0)       // base at centre, ray points outward
            n.eulerAngles.z = CGFloat(i) * .pi / 6
            sparkNode.addChildNode(n)
        }
        sparkNode.position = SCNVector3(0, -0.46, 0.85)
        root.addChildNode(sparkNode)
    }


    /// Props held out in the left hand, in colours that stand apart from the yellow body:
    /// a glowing battery (fill = budget left) or a white mug; plus floating Zzz when asleep.
    private func buildProps() {
        // battery
        let shellG = SCNBox(width: 0.46, height: 0.74, length: 0.24, chamferRadius: 0.1); shellG.materials = [mat(NSColor(red: 0.10, green: 0.10, blue: 0.20, alpha: 1), rough: 0.15, metal: 0.6)]
        battery.addChildNode(SCNNode(geometry: shellG))
        let capG = SCNBox(width: 0.2, height: 0.09, length: 0.14, chamferRadius: 0.03); capG.materials = [mat(NSColor(white: 0.85, alpha: 1), rough: 0.2, metal: 0.8)]
        let cap = SCNNode(geometry: capG); cap.position = SCNVector3(0, 0.4, 0); battery.addChildNode(cap)
        fillMat.lightingModel = .physicallyBased; fillMat.roughness.contents = 0.2
        let fillG = SCNBox(width: 0.34, height: 1, length: 0.26, chamferRadius: 0.05); fillG.materials = [fillMat]
        fillNode.geometry = fillG; fillNode.pivot = SCNMatrix4MakeTranslation(0, -0.5, 0); fillNode.position = SCNVector3(0, -0.31, 0)
        battery.addChildNode(fillNode)
        battery.scale = SCNVector3(1.3, 1.3, 1.3)
        propHold.addChildNode(battery)

        // sparkles around the full battery
        for i in 0..<6 {
            let sp = sphere(0.045, mat(NSColor(red: 1, green: 0.95, blue: 0.7, alpha: 1), rough: 0.1, emissive: true), at: SCNVector3(0, 0, 0))
            let ang = CGFloat(i) * .pi / 3
            sp.position = SCNVector3(cos(ang) * 0.62, sin(ang) * 0.75, 0.1)
            sp.runAction(.sequence([.wait(duration: Double(i) * 0.2), .repeatForever(.sequence([.scale(to: 1.8, duration: 0.45), .scale(to: 0.3, duration: 0.45)]))]))
            sparkles.addChildNode(sp)
        }
        propHold.addChildNode(sparkles)

        // mug
        let body = SCNCylinder(radius: 0.2, height: 0.34); body.materials = [mat(.white, rough: 0.15)]
        mug.addChildNode(SCNNode(geometry: body))
        let h = SCNTorus(ringRadius: 0.1, pipeRadius: 0.035); h.materials = [styled(bandMat, rough: 0.3)]
        let hn = SCNNode(geometry: h); hn.position = SCNVector3(0.23, 0, 0); hn.eulerAngles.x = .pi / 2; mug.addChildNode(hn)
        let band = SCNCylinder(radius: 0.205, height: 0.07); band.materials = [styled(bandMat, rough: 0.3)]
        let bn = SCNNode(geometry: band); bn.position = SCNVector3(0, -0.06, 0); mug.addChildNode(bn)
        let cf = SCNCylinder(radius: 0.17, height: 0.01); cf.materials = [mat(NSColor(red: 0.28, green: 0.14, blue: 0.08, alpha: 1), rough: 0.3)]
        let cn = SCNNode(geometry: cf); cn.position = SCNVector3(0, 0.17, 0); mug.addChildNode(cn)
        for i in 0..<3 {   // steam
            let st = sphere(0.06, { let m = mat(.white, rough: 0.9); m.transparency = 0.55; return m }(), at: SCNVector3(CGFloat(i - 1) * 0.08, 0.25, 0))
            st.runAction(.sequence([.wait(duration: Double(i) * 0.5), .repeatForever(.sequence([
                .group([.moveBy(x: 0, y: 0.45, z: 0, duration: 1.5), .fadeOut(duration: 1.5)]),
                .group([.moveBy(x: 0, y: -0.45, z: 0, duration: 0), .fadeIn(duration: 0)])]))]))
            mug.addChildNode(st)
        }
        mug.scale = SCNVector3(1.3, 1.3, 1.3)
        propHold.addChildNode(mug)
        propHold.position = SCNVector3(0, -0.55, 0.4)
        armL.addChildNode(propHold)

        for i in 0..<3 {
            let t = SCNText(string: "Z", extrusionDepth: 1); t.font = NSFont.boldSystemFont(ofSize: 10); t.flatness = 0.1
            t.materials = [mat(.white, rough: 0.3, emissive: true)]
            let n = SCNNode(geometry: t); let sc = 0.03 + 0.012 * CGFloat(i); n.scale = SCNVector3(sc, sc, sc)
            n.position = SCNVector3(1.0 + 0.15 * CGFloat(i), 0.9 + 0.3 * CGFloat(i), 0.3)
            n.runAction(.sequence([.wait(duration: Double(i) * 0.7), .repeatForever(.sequence([
                .group([.moveBy(x: 0.25, y: 0.5, z: 0, duration: 2), .fadeOut(duration: 2)]),
                .group([.moveBy(x: -0.25, y: -0.5, z: 0, duration: 0), .fadeIn(duration: 0)])]))]))
            zzz.addChildNode(n)
        }
        root.addChildNode(zzz)
    }

    private func applyProps(_ m: Mood, left: Double) {
        let batt = m == .eager || m == .nervous || m == .worried
        let mugOn = m == .happy
        propHold.isHidden = !(batt || mugOn)
        battery.isHidden = !batt; mug.isHidden = !mugOn
        sparkles.isHidden = true
        let c: NSColor = m == .worried ? theme.low : m == .nervous ? theme.mid : theme.good
        fillMat.diffuse.contents = c; fillMat.emission.contents = c; fillMat.emission.intensity = 1.2
        fillNode.scale = SCNVector3(1, 0.6 * CGFloat(max(0.05, left)), 1)
        fillNode.removeAction(forKey: "blink")
        if m == .worried { fillNode.runAction(.repeatForever(.sequence([.fadeOpacity(to: 0.25, duration: 0.45), .fadeOpacity(to: 1, duration: 0.45)])), forKey: "blink") }
        else { fillNode.opacity = 1 }
        armLBase = (batt || mugOn) ? -2.0 : -1.5708
        armL.removeAction(forKey: "arm")
        armL.eulerAngles.z = armLBase; propHold.eulerAngles.z = -armLBase   // keep the prop upright
    }


    // MARK: cool factor — headphones, mirror shades, token halo, confetti
    private func buildCool() {
        let graphite = mat(NSColor(red: 0.12, green: 0.12, blue: 0.17, alpha: 1), rough: 0.25, metal: 0.7)
        let neon = styled(neonMat, rough: 0.2); neon.emission.intensity = 1.4

        // headphones: arched band + two ear cups with neon rings
        let arch = NSBezierPath()
        arch.appendArc(withCenter: .zero, radius: 0.97, startAngle: 0, endAngle: 180)
        arch.appendArc(withCenter: .zero, radius: 0.85, startAngle: 180, endAngle: 0, clockwise: true); arch.close()
        arch.flatness = 0.005
        let band = SCNShape(path: arch, extrusionDepth: 0.16); band.materials = [graphite]
        let bn = SCNNode(geometry: band); bn.position = SCNVector3(0, 0.2, -0.05); bn.scale = SCNVector3(1, 0.5, 1); root.addChildNode(bn)
        for x in [-1.0, 1.0] as [CGFloat] {
            let cup = SCNCylinder(radius: 0.28, height: 0.22); cup.materials = [graphite]
            let cn = SCNNode(geometry: cup); cn.position = SCNVector3(x * 1.02, 0.2, 0.05); cn.eulerAngles.z = .pi / 2; root.addChildNode(cn)
            let ring = SCNTorus(ringRadius: 0.2, pipeRadius: 0.025); ring.materials = [neon]
            let rn = SCNNode(geometry: ring); rn.position = SCNVector3(x * 1.14, 0.2, 0.05); rn.eulerAngles.z = .pi / 2; root.addChildNode(rn)
        }

        // mirror shades
        let lensG = SCNBox(width: 1.5, height: 0.56, length: 0.1, chamferRadius: 0.25)
        lensG.materials = [mat(NSColor(white: 0.03, alpha: 1), rough: 0.04, metal: 1)]
        shades.addChildNode(SCNNode(geometry: lensG))
        let topLine = SCNBox(width: 1.25, height: 0.03, length: 0.02, chamferRadius: 0.01); topLine.materials = [neon]
        let tl = SCNNode(geometry: topLine); tl.position = SCNVector3(0, 0.25, 0.055); shades.addChildNode(tl)
        let glint = SCNBox(width: 0.05, height: 0.42, length: 0.01, chamferRadius: 0)
        let gm = mat(.white, rough: 0.1, emissive: true); gm.transparency = 0.45; glint.materials = [gm]
        for x in [-0.35, 0.4] as [CGFloat] { let g = SCNNode(geometry: glint); g.position = SCNVector3(x, 0, 0.056); g.eulerAngles.z = 0.5; shades.addChildNode(g) }
        root.addChildNode(shades)
        restShades()

        // token halo: one glowing bead per 10% of budget left
        beadMat.lightingModel = .physicallyBased; beadMat.roughness.contents = 0.1
        for i in 0..<10 {
            let g = SCNSphere(radius: 0.075); g.materials = [beadMat]
            let b = SCNNode(geometry: g); let a = CGFloat(i) * .pi / 5
            b.position = SCNVector3(cos(a) * 2.0, 0, sin(a) * 2.0)
            beads.append(b); orbit.addChildNode(b)
        }
        orbit.position = SCNVector3(0, -0.35, 0); orbit.eulerAngles.x = 0.3
        orbit.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 7)))
        root.addChildNode(orbit)
    }

    private func restShades() {   // pushed up on the forehead
        shades.removeAllActions()
        shades.position = SCNVector3(0, 0.6, 0.3); shades.eulerAngles = SCNVector3(-1.1, 0, 0); shades.scale = SCNVector3(0.5, 0.5, 0.5)
    }
    private func dropShades() {
        let d = 0.35
        let down = SCNAction.group([.move(to: SCNVector3(0, 0.21, 0.47), duration: d), .rotateTo(x: 0, y: 0, z: 0, duration: d), .scale(to: 0.88, duration: d)])
        down.timingMode = .easeOut
        let up = SCNAction.group([.move(to: SCNVector3(0, 0.6, 0.3), duration: 0.4), .rotateTo(x: -1.1, y: 0, z: 0, duration: 0.4), .scale(to: 0.5, duration: 0.4)])
        up.timingMode = .easeInEaseOut
        shades.runAction(.sequence([down, .wait(duration: 2.2), up]), forKey: "drop")
        let sweep = SCNAction.sequence([.move(to: SCNVector3(-0.65, 0, 0.06), duration: 0), .move(to: SCNVector3(0.65, 0, 0.06), duration: 0.45)])
        scan.runAction(.sequence([.wait(duration: d), .unhide(), .repeat(sweep, count: 4), .hide()]), forKey: "scan")
    }
    /// For preview stills: shades down over the eyes.
    func previewShadesDown() { shades.removeAllActions(); shades.position = SCNVector3(0, 0.21, 0.47); shades.eulerAngles = SCNVector3(0, 0, 0); shades.scale = SCNVector3(0.88, 0.88, 0.88) }

    private func applyCool(_ m: Mood, left: Double) {
        coolMode = m == .eager
        shades.isHidden = !coolMode
        if coolMode { restShades() }
        let c: NSColor = m == .worried ? theme.low : m == .nervous ? theme.mid : theme.neon
        beadMat.diffuse.contents = c; beadMat.emission.contents = c; beadMat.emission.intensity = 1.3
        let n = m == .sleepy ? 0 : max(1, Int((left * 10).rounded()))
        for (i, b) in beads.enumerated() { b.isHidden = i >= n }
        orbit.isHidden = m == .sleepy
        // tremble on the last drops
        if left > 0 && left < 0.05 {
            root.runAction(.repeatForever(.customAction(duration: 0.12) { n, t in n.eulerAngles.z = 0.03 * sin(t / 0.12 * .pi * 2) }), forKey: "shake")
        } else { root.removeAction(forKey: "shake"); root.eulerAngles.z = 0 }
    }


    // MARK: extras — cape, skateboard, guitar, visor scan
    private func buildExtras() {
        // cape: coral, flutters from the neck
        let p = NSBezierPath()
        p.move(to: CGPoint(x: -0.5, y: 0)); p.line(to: CGPoint(x: 0.5, y: 0)); p.line(to: CGPoint(x: 1.25, y: -1.9))
        quad(p, to: CGPoint(x: -1.25, y: -1.9), c: CGPoint(x: 0, y: -2.25)); p.close(); p.flatness = 0.005
        let cg = SCNShape(path: p, extrusionDepth: 0.04)
        let cm = styled(capeMat, rough: 0.5); cm.isDoubleSided = true
        cg.materials = [cm]
        cape.geometry = cg; cape.position = SCNVector3(0, 0.5, -0.5); cape.scale = SCNVector3(1.2, 0.72, 1)
        cape.runAction(.repeatForever(.customAction(duration: 1.6) { n, t in
            n.eulerAngles.x = 0.12 * sin(t / 1.6 * .pi * 2); n.eulerAngles.z = 0.04 * sin(t / 1.6 * .pi * 4)
        }))
        root.addChildNode(cape)

        // hoverboard: floats on glowing thrusters
        let deck = SCNBox(width: 1.55, height: 0.08, length: 0.52, chamferRadius: 0.04)
        deck.materials = [styled(deckMat, rough: 0.2, metal: 0.8)]
        board.addChildNode(SCNNode(geometry: deck))
        let rimG = SCNBox(width: 1.62, height: 0.025, length: 0.58, chamferRadius: 0.012)
        let rm = styled(railMat, rough: 0.2); rm.emission.intensity = 1.6
        rimG.materials = [rm]; let rimN = SCNNode(geometry: rimG); rimN.position = SCNVector3(0, -0.045, 0); board.addChildNode(rimN)
        let fm = styled(thrustMat, rough: 0.2); fm.emission.intensity = 1.8
        for x in [-0.45, 0.45] as [CGFloat] {
            let t = SCNCylinder(radius: 0.17, height: 0.05); t.materials = [fm]
            let tn = SCNNode(geometry: t); tn.position = SCNVector3(x, -0.1, 0); board.addChildNode(tn)
            let cone = SCNCone(topRadius: 0.16, bottomRadius: 0.02, height: 0.2)
            let cm2 = styled(coneMat, rough: 0.5); cm2.transparency = 0.4; cone.materials = [cm2]
            let cn = SCNNode(geometry: cone); cn.pivot = SCNMatrix4MakeTranslation(0, 0.1, 0); cn.position = SCNVector3(x, -0.12, 0)
            cn.runAction(.repeatForever(.sequence([.scale(to: 1.25, duration: 0.25), .scale(to: 0.85, duration: 0.25)])))
            flames.addChildNode(cn)
        }
        board.addChildNode(flames)
        board.position = SCNVector3(0, -1.43, 0.1); board.scale = SCNVector3(1.35, 1, 1.15)
        board.runAction(.repeatForever(.customAction(duration: 1.6) { n, t in n.position.y = -1.43 + 0.03 * sin(t / 1.6 * .pi * 2) }))
        root.addChildNode(board)

        // electric guitar (neck points left, held across the belly) - bold colours so it reads at small size
        let gcol = styled(guitarMat, rough: 0.18, metal: 0.4)
        let trim = mat(NSColor(white: 0.96, alpha: 1), rough: 0.25)
        let dark = mat(NSColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1), rough: 0.3, metal: 0.6)
        guitar.addChildNode(sphere(0.44, gcol, scale: SCNVector3(1.1, 0.95, 0.32), at: SCNVector3(0, 0, 0)))
        guitar.addChildNode(sphere(0.32, gcol, scale: SCNVector3(1.1, 0.95, 0.32), at: SCNVector3(-0.5, 0.08, 0)))
        guitar.addChildNode(sphere(0.30, trim, scale: SCNVector3(1.0, 0.7, 0.1), at: SCNVector3(-0.05, -0.06, 0.1)))   // pickguard
        for x in [-0.15, 0.1] as [CGFloat] {
            let pk = SCNBox(width: 0.08, height: 0.36, length: 0.05, chamferRadius: 0.01); pk.materials = [dark]
            let pn = SCNNode(geometry: pk); pn.position = SCNVector3(x, 0, 0.16); guitar.addChildNode(pn)
        }
        let neck = SCNBox(width: 1.5, height: 0.16, length: 0.09, chamferRadius: 0.02); neck.materials = [mat(NSColor(red: 0.85, green: 0.62, blue: 0.35, alpha: 1), rough: 0.4)]
        let nn = SCNNode(geometry: neck); nn.position = SCNVector3(-1.2, 0.08, 0.03); guitar.addChildNode(nn)
        let fret = SCNBox(width: 1.45, height: 0.1, length: 0.03, chamferRadius: 0); fret.materials = [dark]
        let fn = SCNNode(geometry: fret); fn.position = SCNVector3(-1.2, 0.08, 0.09); guitar.addChildNode(fn)
        let head = SCNBox(width: 0.36, height: 0.24, length: 0.07, chamferRadius: 0.04); head.materials = [trim]
        let hn = SCNNode(geometry: head); hn.position = SCNVector3(-2.1, 0.1, 0.03); guitar.addChildNode(hn)
        for i in 0..<3 { for sgn in [-1.0, 1.0] as [CGFloat] {
            guitar.addChildNode(sphere(0.035, dark, at: SCNVector3(-2.05 - CGFloat(i) * 0.08, 0.1 + sgn * 0.13, 0.09)))
        } }
        guitar.position = SCNVector3(0.3, -0.55, 0.55); guitar.eulerAngles.z = -0.2; guitar.scale = SCNVector3(0.6, 0.6, 0.6)
        root.addChildNode(guitar)

        // laser scan across the shades
        let sc = SCNBox(width: 0.06, height: 0.5, length: 0.02, chamferRadius: 0.01)
        let sm = styled(scanMat, rough: 0.1); sm.emission.intensity = 2
        sc.materials = [sm]; scan.geometry = sc; scan.position = SCNVector3(-0.65, 0, 0.06); scan.isHidden = true
        shades.addChildNode(scan)
    }

    private func startStrum() {
        armR.runAction(.repeatForever(.customAction(duration: 0.4) { n, t in n.eulerAngles.z = -0.9 + 0.25 * sin(t / 0.4 * .pi * 2) }), forKey: "arm")
    }
    /// Hoverboard thrusters flare and leave a neon trail while the window glides in (dir +1) or out (dir -1).
    func boost(_ d: Double, dir: CGFloat) {
        guard !board.isHidden else { return }
        flames.runAction(.sequence([.scale(to: 1.7, duration: 0.3), .wait(duration: d - 0.6), .scale(to: 1, duration: 0.3)]), forKey: "boost")
        let img = NSImage(size: NSSize(width: 8, height: 8), flipped: false) { r in NSColor.white.setFill(); NSBezierPath(ovalIn: r).fill(); return true }
        let ps = SCNParticleSystem()
        ps.particleImage = img; ps.birthRate = 90; ps.emissionDuration = d; ps.loops = false
        ps.particleLifeSpan = 0.7; ps.particleLifeSpanVariation = 0.2
        ps.particleVelocity = 2.2; ps.particleVelocityVariation = 0.6; ps.spreadingAngle = 25
        ps.emittingDirection = SCNVector3(dir, 0, 0); ps.particleSize = 0.08
        ps.particleColor = theme.thruster; ps.particleColorVariation = SCNVector4(0.5, 0, 0, 0)
        ps.blendMode = .additive; ps.isLightingEnabled = false
        let n = SCNNode(); n.position = SCNVector3(dir * 0.7, -0.1, 0); n.addParticleSystem(ps)
        board.addChildNode(n); n.runAction(.sequence([.wait(duration: d + 1), .removeFromParentNode()]))
    }

    private func applyExtras(_ m: Mood, left: Double) {
        let great = m == .eager
        guitarMode = m == .eager && left >= 0.9
        cape.isHidden = !great
        board.isHidden = !(great || m == .happy)
        shadowNode.position.y = board.isHidden ? -1.4 : -1.88
        guitar.isHidden = !guitarMode
        if guitarMode {
            propHold.isHidden = true
            armLBase = -1.5708; armL.removeAction(forKey: "arm"); armL.eulerAngles.z = -1.5708; propHold.eulerAngles.z = 1.5708
            armRBase = -0.9; startStrum()
        } else {
            armRBase = 1.5708; armR.removeAction(forKey: "arm"); armR.eulerAngles.z = 1.5708
        }
    }

    private static func envImage() -> NSImage {
        NSImage(size: NSSize(width: 256, height: 128), flipped: false) { r in
            NSGradient(colors: [NSColor(red: 1, green: 0.97, blue: 0.9, alpha: 1),
                                NSColor(red: 0.6, green: 0.7, blue: 0.95, alpha: 1),
                                NSColor(red: 0.25, green: 0.2, blue: 0.35, alpha: 1)])!.draw(in: r, angle: 90)
            return true
        }
    }

    // MARK: faces
    private func quad(_ p: NSBezierPath, to e: CGPoint, c: CGPoint) {
        let s = p.currentPoint
        p.curve(to: e, controlPoint1: CGPoint(x: s.x + 2 / 3 * (c.x - s.x), y: s.y + 2 / 3 * (c.y - s.y)),
                controlPoint2: CGPoint(x: e.x + 2 / 3 * (c.x - e.x), y: e.y + 2 / 3 * (c.y - e.y)))
    }
    private func mouthShape(_ m: Mood) -> SCNNode {
        let p = NSBezierPath(); var color = NSColor(red: 0.30, green: 0.10, blue: 0.10, alpha: 1)
        switch m {
        case .happy, .eager:   // warm smile (no open-mouth celebration)
            p.move(to: CGPoint(x: -0.22, y: 0.02)); quad(p, to: CGPoint(x: 0.22, y: 0.02), c: CGPoint(x: 0, y: -0.26))
            quad(p, to: CGPoint(x: -0.22, y: 0.02), c: CGPoint(x: 0, y: -0.09)); p.close()
        case .nervous:   // flat, unsure mouth
            p.move(to: CGPoint(x: -0.17, y: -0.02)); quad(p, to: CGPoint(x: 0.17, y: -0.02), c: CGPoint(x: 0, y: 0.05))
            quad(p, to: CGPoint(x: -0.17, y: -0.02), c: CGPoint(x: 0, y: -0.03)); p.close()
        case .worried:
            p.move(to: CGPoint(x: -0.2, y: -0.08)); quad(p, to: CGPoint(x: 0.2, y: -0.08), c: CGPoint(x: 0, y: 0.18))
            quad(p, to: CGPoint(x: -0.2, y: -0.08), c: CGPoint(x: 0, y: 0.07)); p.close()
        case .sleepy:
            p.append(NSBezierPath(ovalIn: NSRect(x: -0.07, y: -0.09, width: 0.14, height: 0.18))); color = NSColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 1)
        }
        p.flatness = 0.005
        let shape = SCNShape(path: p, extrusionDepth: 0.04)
        let mm = SCNMaterial(); mm.lightingModel = .physicallyBased; mm.diffuse.contents = color; mm.roughness.contents = 0.4
        shape.materials = [mm]
        let n = SCNNode(geometry: shape)
        return n
    }

    /// Re-colour everything for a theme (card colours live in SwiftUI).
    func setTheme(_ t: Theme) {
        theme = t
        func paint(_ m: SCNMaterial, _ c: NSColor, glow: Bool = false) { m.diffuse.contents = c; if glow { m.emission.contents = c } }
        paint(neonMat, t.neon, glow: true); paint(railMat, t.neon, glow: true)
        paint(thrustMat, t.thruster, glow: true); paint(coneMat, t.thruster, glow: true); paint(scanMat, t.laser, glow: true)
        paint(capeMat, t.cape); capeMat.emission.contents = t.capeGlow
        paint(guitarMat, t.guitar); paint(deckMat, t.deck); paint(bandMat, t.band)
        rimNode.light?.color = t.rim
        applyProps(lastMood, left: lastLeft); applyCool(lastMood, left: lastLeft)   // retint tier colours
    }

    func setMood(_ m: Mood) {
        asleep = m == .sleepy
        let sc: SCNVector3 = m == .sleepy ? SCNVector3(1, 0.12, 1) : (m == .worried || m == .nervous) ? SCNVector3(0.92, 0.85, 1) : SCNVector3(1, 1, 1)
        for e in [eyeL, eyeR] { e.scale = sc; e.position.y = cy(1) + (m == .worried ? -0.03 : 0) }
        sweat.isHidden = m != .worried
        zzz.isHidden = !asleep
    }

    // MARK: animation
    private func blink() {
        guard !asleep else { return }
        for e in [eyeL, eyeR] { e.runAction(.sequence([.scale(to: 0.05, duration: 0.07), .scale(to: 1, duration: 0.09)])) }
    }
    private func look() {
        let dx = CGFloat.random(in: -0.03...0.03), dy = CGFloat.random(in: -0.02...0.02)
        for p in pupils { p.runAction(.move(to: SCNVector3(dx, dy, 0), duration: 0.25)) }
        if coolMode && wink == false && Int.random(in: 0..<4) == 0 {   // eager: playful wink at you
            wink = true
            eyeR.runAction(.sequence([.scale(to: 0.05, duration: 0.1), .wait(duration: 0.4), .scale(to: 1, duration: 0.12)])) { [weak self] in self?.wink = false }
        }
    }
    func wave() {
        guard !guitarMode else { return }
        let base = armRBase
        let up = SCNAction.customAction(duration: 1.4) { [armR] n, t in armR.eulerAngles.z = 2.3 + 0.35 * sin(t * 14) }
        let down = SCNAction.customAction(duration: 0.3) { [armR] n, t in armR.eulerAngles.z = 2.3 + (base - 2.3) * (t / 0.3) }
        armR.runAction(.sequence([up, down]), forKey: "arm")
    }
    /// Arrival. With lots of budget left it is a friendly nudge: impatient little bounces, leaning toward you,
    /// beckoning "come on, use me!" - never a celebration. Otherwise just a calm hello.
    func arrive() {
        guard coolMode else { wave(); return }
        dropShades()
        func tap(_ h: CGFloat) -> SCNAction {
            let up = SCNAction.moveBy(x: 0, y: h, z: 0, duration: 0.16); up.timingMode = .easeOut
            let dn = SCNAction.moveBy(x: 0, y: -h, z: 0, duration: 0.16); dn.timingMode = .easeIn
            return .sequence([up, dn])
        }
        root.runAction(.sequence([tap(0.14), .wait(duration: 0.3), tap(0.14), .wait(duration: 0.3), tap(0.14)]), forKey: "hop")
        root.runAction(.sequence([.rotateBy(x: 0.16, y: 0, z: 0, duration: 0.4), .wait(duration: 1.6), .rotateBy(x: -0.16, y: 0, z: 0, duration: 0.4)]), forKey: "lean")
        guard !guitarMode else { return }
        let d = 2.0, base = armRBase
        armR.runAction(.customAction(duration: d) { [armR] n, t in      // beckoning come-here motion
            let ramp = min(1, t / 0.25) * min(1, (d - t) / 0.25)
            armR.eulerAngles.z = base + (2.0 + 0.5 * sin(t * 10) - base) * ramp
        }, forKey: "arm")
    }
    /// Walk away: hop off the board, turn sideways and take slow alternating steps with swinging arms and a waddle.
    func walkOut(dir: CGFloat) { startWalk(facing: dir, boardGone: false) }
    /// Walk in: arrive already turned sideways in the direction of travel, board tucked away.
    func walkIn(facing: CGFloat) { startWalk(facing: facing, boardGone: true) }
    /// Stop walking, turn to face the viewer and bring the hoverboard back under the feet.
    func stopWalk() {
        root.removeAction(forKey: "walk")
        root.runAction(.rotateTo(x: 0, y: 0, z: 0, duration: 0.6, usesShortestUnitArc: true), forKey: "turn")
        for (i, b) in boots.enumerated() { b.position = bootBase[i] }
        armL.eulerAngles.x = 0; armR.eulerAngles.x = 0
        board.removeAction(forKey: "fade"); board.runAction(.fadeIn(duration: 0.6), forKey: "fade")
        shadowNode.position.y = board.isHidden ? -1.4 : -1.88
        flames.runAction(.sequence([.scale(to: 1.7, duration: 0.3), .scale(to: 1, duration: 0.5)]), forKey: "boost")
    }
    private func startWalk(facing dir: CGFloat, boardGone: Bool) {
        board.removeAction(forKey: "fade")
        if boardGone { board.opacity = 0 } else { board.runAction(.fadeOut(duration: 0.4), forKey: "fade") }
        shadowNode.position.y = -1.4
        root.runAction(.rotateTo(x: 0, y: dir * 1.15, z: 0, duration: 0.6, usesShortestUnitArc: true), forKey: "turn")
        let period = 0.9
        root.runAction(.repeatForever(.customAction(duration: period) { [weak self] n, t in
            guard let self else { return }
            let ph = t / period * .pi * 2
            for (i, b) in self.boots.enumerated() {
                let p = ph + (i % 2 == 0 ? 0 : .pi)
                b.position.z = self.bootBase[i].z + 0.2 * sin(p); b.position.y = self.bootBase[i].y + max(0, cos(p)) * 0.14
            }
            self.armL.eulerAngles.x = 0.6 * sin(ph); self.armR.eulerAngles.x = -0.6 * sin(ph)
            n.eulerAngles.z = 0.05 * sin(ph)
        }), forKey: "walk")
    }
    /// For preview stills: a frozen mid-stride pose.
    func previewWalk() {
        board.opacity = 0; shadowNode.position.y = -1.4
        root.eulerAngles = SCNVector3(0, 1.15, 0.04)
        boots[0].position.y += 0.12; boots[0].position.z += 0.2; boots[1].position.z -= 0.15
        boots[2].position.y += 0.12; boots[2].position.z += 0.2; boots[3].position.z -= 0.15
        armL.eulerAngles.x = 0.5; armR.eulerAngles.x = -0.5
    }
    func resetWalk() {
        root.removeAction(forKey: "walk"); root.removeAction(forKey: "turn")
        root.eulerAngles = SCNVector3(0, 0, 0)
        for (i, b) in boots.enumerated() { b.position = bootBase[i] }
        armL.eulerAngles.x = 0; armR.eulerAngles.x = 0
        board.removeAction(forKey: "fade"); board.opacity = 1
    }

    /// Slow friendly wave before sliding out.
    func goodbye() {
        let d = 1.2, base = armRBase
        armR.runAction(.sequence([
            .customAction(duration: d) { [armR] n, t in
                let ramp = min(1, t / 0.25) * min(1, (d - t) / 0.25)
                armR.eulerAngles.z = base + (2.3 - base + 0.35 * sin(t * 9)) * ramp
            },
            .run { [weak self] _ in if self?.guitarMode == true { self?.startStrum() } }
        ]), forKey: "arm")
    }

    func hop() {
        let up = SCNAction.moveBy(x: 0, y: 0.55, z: 0, duration: 0.22); up.timingMode = .easeOut
        let dn = SCNAction.moveBy(x: 0, y: -0.55, z: 0, duration: 0.22); dn.timingMode = .easeIn
        root.runAction(.sequence([up, dn]), forKey: "hop")
        wave()
    }

    /// used: 0...1 fraction of daily budget consumed. Face and props follow what's LEFT.
    func update(used: Double) {
        let left = 1 - used
        resetWalk()
        let mood: Mood = left <= 0 ? .sleepy : left < 0.2 ? .worried : left < 0.4 ? .nervous : left < 0.6 ? .happy : .eager
        lastMood = mood; lastLeft = left
        setMood(mood); applyProps(mood, left: left)
        applyCool(mood, left: left); applyExtras(mood, left: left)
    }
}
