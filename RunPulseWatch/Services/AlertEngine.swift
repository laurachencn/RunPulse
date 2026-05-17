import Foundation
import WatchKit

@MainActor
final class AlertEngine: ObservableObject {
    @Published var isAlerting: Bool = false
    @Published var alertCount: Int = 0
    @Published var lastAlertTime: Date?
    
    private let threshold: Int
    private let hysteresis: Int = 5
    
    init(threshold: Int) {
        self.threshold = threshold
    }
    
    func checkHeartRate(_ heartRate: Double) {
        let hr = Int(heartRate)
        
        if hr > threshold && !isAlerting {
            triggerAlert()
        } else if hr <= threshold - hysteresis && isAlerting {
            clearAlert()
        }
    }
    
    private func triggerAlert() {
        isAlerting = true
        alertCount += 1
        lastAlertTime = Date()
        triggerHapticAlert()
        guard !VoiceService.shared.isSpeaking else { return }
        Task {
            await VoiceService.shared.speak("Heart rate high, slow down")
        }
    }
    
    private func clearAlert() {
        isAlerting = false
    }
    
    private func triggerHapticAlert() {
        let device = WKInterfaceDevice.current()
        device.play(.click)
    }
    
    func reset() {
        isAlerting = false
        alertCount = 0
        lastAlertTime = nil
    }
}
