import Foundation
import UserNotifications
import WatchConnectivity

@MainActor
final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var isPaired = false
    @Published var isReachable = false
    @Published var lastReceivedRun: RunSession?
    
    private let session = WCSession.default
    
    override init() {
        super.init()
        session.delegate = self
        session.activate()
        updateSessionState()
    }
    
    private func updateSessionState() {
        isPaired = session.isPaired
        isReachable = session.isReachable
    }
    
    func sendToWatch(_ message: [String: Any]) {
        guard session.isReachable else {
            try? session.updateApplicationContext(message)
            return
        }
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message: \(error)")
        }
    }
    
    func sendRunSession(_ session: RunSession) {
        do {
            let data = try JSONEncoder().encode(session)
            let message = ["runSession": data]
            sendToWatch(message)
        } catch {
            print("Failed to encode run session: \(error)")
        }
    }
    
    func sendSettingsUpdate(threshold: Int) {
        let message: [String: Any] = ["alertThreshold": threshold]
        sendToWatch(message)
    }
    
    func sendAudioCueConfig(_ config: AudioCueConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            let message: [String: Any] = ["audioCueConfig": data]
            sendToWatch(message)
        } catch {
            print("Failed to encode audio cue config: \(error)")
        }
    }
    
    func deliverThresholdNotification() {
        let content = UNMutableNotificationContent()
        content.title = "RunPulse"
        content.body = "Heart rate exceeded threshold — slow down"
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: "hr-threshold-breach",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            updateSessionState()
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateSessionState()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if let runSessionData = message["runSession"] as? Data {
                do {
                    let runSession = try JSONDecoder().decode(RunSession.self, from: runSessionData)
                    lastReceivedRun = runSession
                    await StorageManager.shared.saveRun(runSession)
                    await VoiceService.shared.speak(runSession.voiceSummaryText)
                } catch {
                    print("Failed to decode run session: \(error)")
                }
            }
            if message["thresholdBreach"] as? Bool == true {
                deliverThresholdNotification()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if let runSessionData = applicationContext["runSession"] as? Data {
                do {
                    let runSession = try JSONDecoder().decode(RunSession.self, from: runSessionData)
                    lastReceivedRun = runSession
                    await StorageManager.shared.saveRun(runSession)
                    await VoiceService.shared.speak(runSession.voiceSummaryText)
                } catch {
                    print("Failed to decode run session from context: \(error)")
                }
            }
            if applicationContext["thresholdBreach"] as? Bool == true {
                deliverThresholdNotification()
            }
        }
    }
}
