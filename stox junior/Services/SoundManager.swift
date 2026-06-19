import AVFoundation

final class SoundManager {
    static let shared = SoundManager()
    static var isDisabled = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    func playKaChing() {
        guard !SoundManager.isDisabled else { return }
        schedule(frequency: 400,  duration: 0.01,  amplitude: 0.35, delay: 0.1)
        schedule(frequency: 523,  duration: 0.008,  amplitude: 0.24, delay: 0.035)
    }

    func playCelebration() {
        guard !SoundManager.isDisabled else { return }
        // Same shape as ka-ching (burst + bell) but slightly higher pitch, quick triple
        schedule(frequency: 500,  duration: 0.012, amplitude: 0.35, delay: 0.00)
        schedule(frequency: 620,  duration: 0.012, amplitude: 0.30, delay: 0.05)
        schedule(frequency: 740,  duration: 0.08, amplitude: 0.26, delay: 0.10)
    }

    // MARK: - Private

    private func schedule(frequency: Float, duration: Double, amplitude: Float, delay: Double) {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, let buffer = self.makeBuffer(frequency: frequency, duration: duration, amplitude: amplitude) else { return }
            if !self.engine.isRunning { try? self.engine.start() }
            if !self.player.isPlaying { self.player.play() }
            self.player.scheduleBuffer(buffer, completionHandler: nil)
        }
    }

    private func makeBuffer(frequency: Float, duration: Double, amplitude: Float) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let fade = min(Int(sampleRate * 0.01), Int(frameCount) / 4)
        for i in 0..<Int(frameCount) {
            let t = Float(i) / Float(sampleRate)
            let env: Float
            if i < fade {
                env = Float(i) / Float(fade)
            } else if i > Int(frameCount) - fade {
                env = Float(Int(frameCount) - i) / Float(fade)
            } else {
                env = 1.0
            }
            data[i] = amplitude * env * sin(2 * .pi * frequency * t)
        }
        return buffer
    }
}
