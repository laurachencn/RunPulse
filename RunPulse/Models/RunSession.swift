import Foundation

struct RunSession: Codable, Identifiable, Hashable {
    let id: UUID
    var startDate: Date
    var endDate: Date?
    var totalDuration: TimeInterval
    var totalDistance: Double
    var totalCalories: Double
    var averageHeartRate: Double
    var maxHeartRate: Double
    var averagePace: TimeInterval
    var splits: [KilometerSplit]
    var isCompleted: Bool
    
    var totalDistanceKm: Double {
        totalDistance / 1000.0
    }
    
    var durationString: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var averagePaceString: String {
        let minutes = Int(averagePace) / 60
        let seconds = Int(averagePace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    static func newSession() -> RunSession {
        RunSession(
            id: UUID(),
            startDate: Date(),
            endDate: nil,
            totalDuration: 0,
            totalDistance: 0,
            totalCalories: 0,
            averageHeartRate: 0,
            maxHeartRate: 0,
            averagePace: 0,
            splits: [],
            isCompleted: false
        )
    }
}
