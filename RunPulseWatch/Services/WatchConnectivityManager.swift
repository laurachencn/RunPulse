import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isPaired = false
    @Published var isReachable = false
    
    private let session = WCSession.default
    
    override init() {
        super.init()
        session.delegate = self
        session.activate()
        updateSessionState()
    }
    
    private func updateSessionState() {
        #if os(watchOS)
        isPaired = true
        #else
        isPaired = session.isPaired
        #endif
        isReachable = session.isReachable
    }
    
    func sendRunSession(_ session: RunSession) {
        do {
            let data = try JSONEncoder().encode(session)
            let message: [String: Any] = ["runSession": data]
            sendToWatch(message)
        } catch {
            print("Failed to encode run session: \(error)")
        }
    }
    
    func sendSettingsUpdate(threshold: Int) {
        let message: [String: Any] = ["alertThreshold": threshold]
        sendToWatch(message)
    }
    
    func sendThresholdBreach() {
        let message: [String: Any] = ["thresholdBreach": true]
        sendToWatch(message)
    }
    
    private func sendToWatch(_ message: [String: Any]) {
        guard session.isReachable else {
            try? session.updateApplicationContext(message)
            return
        }
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message to iPhone: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            updateSessionState()
        }
    }
    
    #if !os(watchOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateSessionState()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if let threshold = message["alertThreshold"] as? Int {
                UserDefaults.standard.set(threshold, forKey: "alertThreshold")
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let threshold = applicationContext["alertThreshold"] as? Int {
                UserDefaults.standard.set(threshold, forKey: "alertThreshold")
            }
        }
    }
}
