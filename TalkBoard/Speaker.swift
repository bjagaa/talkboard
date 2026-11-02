import AVFoundation

/// Text-to-speech using the iPad's built-in voices. Works offline.
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    private init() {
        // .playback lets the voice play even when the iPad's silent switch / mute is on.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func speak(_ text: String, settings: AppSettings) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(string: trimmed)
        u.rate = settings.rate
        if let id = settings.voiceIdentifier, let v = AVSpeechSynthesisVoice(identifier: id) {
            u.voice = v
        } else {
            u.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        synth.speak(u)
    }

    /// English voices installed on this iPad, best quality first.
    /// More voices: iPad Settings > Accessibility > Spoken Content > Voices.
    static var englishVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { a, b in
                a.quality.rawValue != b.quality.rawValue
                    ? a.quality.rawValue > b.quality.rawValue
                    : a.name < b.name
            }
    }
}
