import AVFoundation
import AudioToolbox

class AudioManager {
    static let shared = AudioManager()

    private var audioEngine: AVAudioEngine?
    private var isMuted: Bool { GamePersistence.shared.isMuted }

    // Charge sound state
    private var chargePlayerNode: AVAudioPlayerNode?
    private var isChargeSoundPlaying = false

    private init() {
        setupAudioSession()
        setupEngine()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    private func setupEngine() {
        audioEngine = AVAudioEngine()
        do {
            try audioEngine?.start()
        } catch {
            print("Audio engine start failed: \(error)")
        }
    }

    func toggleMute() {
        GamePersistence.shared.isMuted = !GamePersistence.shared.isMuted
        if GamePersistence.shared.isMuted {
            stopChargeSound()
        }
    }

    // MARK: - Sound Effects using AudioToolbox for simplicity
    func playSound(_ type: SoundType) {
        guard !isMuted else { return }

        guard let engine = audioEngine, engine.isRunning else {
            setupEngine()
            return
        }

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.synthesizeSound(type)
        }
    }

    private func synthesizeSound(_ type: SoundType) {
        guard let engine = audioEngine else { return }

        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        let params = type.parameters
        let frameCount = AVAudioFrameCount(sampleRate * params.duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / params.duration

            // Frequency sweep
            let freq = params.startFreq + (params.endFreq - params.startFreq) * progress

            // Waveform
            let phase = 2.0 * Double.pi * freq * t
            var sample: Float

            switch params.waveform {
            case .sine:
                sample = Float(sin(phase))
            case .triangle:
                sample = Float(2.0 * abs(2.0 * (t * freq - floor(t * freq + 0.5))) - 1.0)
            case .square:
                sample = sin(phase) >= 0 ? 1.0 : -1.0
            case .sawtooth:
                sample = Float(2.0 * (t * freq - floor(t * freq + 0.5)))
            }

            // Amplitude envelope
            let amplitude = Float(params.startAmp * pow(params.endAmp / max(params.startAmp, 0.001), progress))
            channelData[i] = sample * amplitude
        }

        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)

        playerNode.scheduleBuffer(buffer) {
            DispatchQueue.main.async {
                engine.detach(playerNode)
            }
        }
        playerNode.play()
    }

    // MARK: - Charge Sound
    func startChargeSound() {
        guard !isMuted, !isChargeSoundPlaying else { return }
        guard let engine = audioEngine, engine.isRunning else { return }

        isChargeSoundPlaying = true

        let sampleRate: Double = 44100
        let duration: Double = 2.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                let progress = t / duration
                let freq = 200.0 + 600.0 * progress
                let phase = 2.0 * Double.pi * freq * t
                let sample = Float(2.0 * abs(2.0 * (t * freq - floor(t * freq + 0.5))) - 1.0)
                let amp = Float(min(progress * 10.0, 1.0) * 0.1)
                channelData[i] = sample * amp
            }
        }

        let playerNode = AVAudioPlayerNode()
        chargePlayerNode = playerNode
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    func stopChargeSound() {
        chargePlayerNode?.stop()
        if let node = chargePlayerNode, let engine = audioEngine {
            engine.detach(node)
        }
        chargePlayerNode = nil
        isChargeSoundPlaying = false
    }

    // MARK: - Haptic Feedback
    func vibrate(_ style: VibrateStyle) {
        switch style {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - Sound Types
enum SoundType {
    case jump, land, combo, hit, gameover, perfect

    struct Parameters {
        let waveform: Waveform
        let startFreq: Double
        let endFreq: Double
        let startAmp: Double
        let endAmp: Double
        let duration: Double
    }

    var parameters: Parameters {
        switch self {
        case .jump:
            return Parameters(waveform: .triangle, startFreq: 180, endFreq: 520,
                            startAmp: 0.2, endAmp: 0.01, duration: 0.15)
        case .land:
            return Parameters(waveform: .sine, startFreq: 130, endFreq: 45,
                            startAmp: 0.25, endAmp: 0.01, duration: 0.12)
        case .combo:
            return Parameters(waveform: .square, startFreq: 500, endFreq: 1000,
                            startAmp: 0.1, endAmp: 0.01, duration: 0.15)
        case .hit:
            return Parameters(waveform: .sawtooth, startFreq: 120, endFreq: 20,
                            startAmp: 0.25, endAmp: 0.01, duration: 0.25)
        case .gameover:
            return Parameters(waveform: .sawtooth, startFreq: 300, endFreq: 50,
                            startAmp: 0.2, endAmp: 0.01, duration: 0.5)
        case .perfect:
            return Parameters(waveform: .sine, startFreq: 600, endFreq: 1200,
                            startAmp: 0.12, endAmp: 0.01, duration: 0.25)
        }
    }
}

enum Waveform {
    case sine, triangle, square, sawtooth
}

enum VibrateStyle {
    case light, medium, heavy, success, error
}
