import AVFoundation

/// Tiny synthesized cute sounds (no audio assets needed).
final class Sound {
    enum Kind { case show, hide, pop, sad, copied, nudge, step }
    var enabled = true
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let fmt = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    private var buffers: [Kind: AVAudioPCMBuffer] = [:]

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: fmt)
        engine.mainMixerNode.outputVolume = 0.45
        buffers[.show] = make([(520, 780, 0.11), (780, 1040, 0.15)])
        buffers[.hide] = make([(1000, 800, 0.10), (800, 620, 0.12), (620, 430, 0.2)])
        buffers[.pop] = make([(850, 1250, 0.08)])
        buffers[.copied] = make([(784, 988, 0.07), (988, 1318, 0.11)])
        buffers[.nudge] = make([(700, 700, 0.07), (940, 940, 0.12)])   // friendly hey! ding-ding
        buffers[.step] = make([(320, 190, 0.045)])
        buffers[.sad] = make([(520, 400, 0.18), (400, 260, 0.30)])
        try? engine.start()
    }

    func play(_ k: Kind) {
        guard enabled, let b = buffers[k] else { return }
        if !engine.isRunning { try? engine.start() }
        player.scheduleBuffer(b, at: nil)
        if !player.isPlaying { player.play() }
    }

    private func make(_ notes: [(Double, Double, Double)]) -> AVAudioPCMBuffer {
        let sr = fmt.sampleRate
        let total = Int(notes.reduce(0) { $0 + $1.2 + 0.015 } * sr)
        let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(total))!
        buf.frameLength = AVAudioFrameCount(total)
        let ch = buf.floatChannelData![0]
        var i = 0
        for (f0, f1, dur) in notes {
            let n = Int(dur * sr); var phase = 0.0
            for s in 0..<n where i < total {
                let t = Double(s) / sr, k = t / dur
                let f = f0 + (f1 - f0) * k + 7 * sin(2 * .pi * 7 * t)       // glide + cute vibrato
                phase += 2 * .pi * f / sr
                let env = min(1, t / 0.006) * exp(-2.6 * k)                  // pluck envelope
                ch[i] = Float((sin(phase) + 0.25 * sin(2 * phase) + 0.08 * sin(3 * phase)) * env * 0.4)
                i += 1
            }
            i += Int(0.015 * sr)
        }
        return buf
    }
}
