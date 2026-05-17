import Foundation
import AVFoundation

@MainActor
final class VoiceService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var speechContinuation: CheckedContinuation<Void, Never>?
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
    
    func speak(_ text: String) async {
        if UserDefaults.standard.object(forKey: "voiceEnabled") as? Bool == false { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.voice = bestAvailableVoice()
        
        await withCheckedContinuation { continuation in
            speechContinuation = continuation
            synthesizer.speak(utterance)
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        speechContinuation?.resume()
        speechContinuation = nil
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            speechContinuation?.resume()
            speechContinuation = nil
        }
    }
    
    private func bestAvailableVoice() -> AVSpeechSynthesisVoice {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let enVoices = voices.filter { $0.language.hasPrefix("en-US") }
        
        let qualityOrder: [AVSpeechSynthesisVoiceQuality] = [.premium, .enhanced, .default]
        for quality in qualityOrder {
            if let voice = enVoices.first(where: { $0.quality == quality }) {
                return voice
            }
        }
        
        return AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice()
    }
}
