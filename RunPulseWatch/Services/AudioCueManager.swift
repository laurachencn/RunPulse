import Foundation

@MainActor
final class AudioCueManager: ObservableObject {
    @Published var pendingCues: [String] = []
    
    var config: AudioCueConfig
    
    private(set) var totalDistanceAnnounced: Double = 0
    private(set) var lastTimeAnnouncement: Date?
    
    private var lastKnownDistance: Double = 0
    private var lastKnownPace: TimeInterval = 0
    private var lastKnownHeartRate: Double = 0
    private var lastKnownCalories: Double = 0
    
    init(config: AudioCueConfig) {
        self.config = config
    }
    
    func updateMetrics(
        distance: Double,
        pace: TimeInterval,
        heartRate: Double,
        calories: Double,
        currentTime: Date
    ) {
        guard config.voiceEnabled else {
            pendingCues = []
            return
        }
        
        pendingCues = []
        
        let distanceIntervalMeters = config.distanceInterval.rawValue * 1000.0
        if distance >= totalDistanceAnnounced + distanceIntervalMeters {
            let kmAnnounced = (totalDistanceAnnounced + distanceIntervalMeters) / 1000.0
            let cue = buildCue(
                distance: distance,
                pace: pace,
                heartRate: heartRate,
                calories: calories,
                distanceText: formatDistanceAnnouncement(kmAnnounced)
            )
            pendingCues.append(cue)
            totalDistanceAnnounced += distanceIntervalMeters
        }
        
        if config.timeInterval != .off {
            let intervalSeconds = TimeInterval(config.timeInterval.rawValue)
            if let lastAnnouncement = lastTimeAnnouncement {
                if currentTime.timeIntervalSince(lastAnnouncement) >= intervalSeconds {
                    let cue = buildCue(
                        distance: distance,
                        pace: pace,
                        heartRate: heartRate,
                        calories: calories,
                        distanceText: nil
                    )
                    pendingCues.append(cue)
                    lastTimeAnnouncement = currentTime
                }
            } else {
                lastTimeAnnouncement = currentTime
            }
        }
        
        lastKnownDistance = distance
        lastKnownPace = pace
        lastKnownHeartRate = heartRate
        lastKnownCalories = calories
    }
    
    func resetCues() {
        pendingCues = []
    }
    
    func reset() {
        totalDistanceAnnounced = 0
        lastTimeAnnouncement = nil
        pendingCues = []
    }
    
    private func buildCue(
        distance: Double,
        pace: TimeInterval,
        heartRate: Double,
        calories: Double,
        distanceText: String?
    ) -> String {
        var parts: [String] = []
        
        if let distanceText = distanceText {
            parts.append(distanceText)
        }
        
        if config.announcePace {
            parts.append("Your pace is \(formatPace(pace)) per kilometer")
        }
        
        if config.announceHeartRate {
            parts.append("Your heart rate is \(Int(heartRate)) beats per minute")
        }
        
        if config.announceCalories {
            parts.append("You've burned \(Int(calories)) calories")
        }
        
        return parts.joined(separator: ". ")
    }
    
    private func formatDistanceAnnouncement(_ km: Double) -> String {
        if km == 1.0 {
            return "You've run 1 kilometer"
        }
        return "You've run \(Int(km)) kilometers"
    }
    
    private func formatPace(_ pace: TimeInterval) -> String {
        guard pace > 0 else { return "not available" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        if minutes > 0 {
            return "\(minutes) minutes \(seconds) seconds"
        }
        return "\(seconds) seconds"
    }
}
