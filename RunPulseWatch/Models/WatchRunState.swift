import Foundation

enum RunState: String, Codable {
    case notStarted
    case running
    case paused
    case completed
}

struct WatchRunState: Codable {
    var state: RunState
    var currentHeartRate: Double
    var averageHeartRate: Double
    var currentPace: TimeInterval
    var currentDistance: Double
    var currentDuration: TimeInterval
    var currentKilometer: Int
    var alertThreshold: Int
    var isAlerting: Bool
    var lastSplit: KilometerSplit?
    var totalCalories: Double
    
    static var idle: WatchRunState {
        WatchRunState(
            state: .notStarted,
            currentHeartRate: 0,
            averageHeartRate: 0,
            currentPace: 0,
            currentDistance: 0,
            currentDuration: 0,
            currentKilometer: 0,
            alertThreshold: 171,
            isAlerting: false,
            lastSplit: nil,
            totalCalories: 0
        )
    }
}
