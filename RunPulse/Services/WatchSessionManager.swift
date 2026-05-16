import Foundation
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
                } catch {
                    print("Failed to decode run session: \(error)")
                }
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
                } catch {
                    print("Failed to decode run session from context: \(error)")
                }
            }
        }
    }
}
