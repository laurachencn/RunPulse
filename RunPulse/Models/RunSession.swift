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
    
    var voiceSummaryText: String {
        let distanceText = String(format: "%.1f", totalDistanceKm)
        let durationText = formattedDurationForVoice
        let avgHRText = "\(Int(averageHeartRate))"
        let maxHRText = "\(Int(maxHeartRate))"
        let paceText = formattedPaceForVoice
        let caloriesText = "\(Int(totalCalories))"
        
        return "You ran \(distanceText) kilometers in \(durationText). Average heart rate: \(avgHRText) beats per minute. Max heart rate: \(maxHRText). Average pace: \(paceText) per kilometer. You burned \(caloriesText) calories."
    }
    
    private var formattedDurationForVoice: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60
        if hours > 0 {
            return "\(hours) hours \(minutes) minutes and \(seconds) seconds"
        }
        return "\(minutes) minutes and \(seconds) seconds"
    }
    
    private var formattedPaceForVoice: String {
        guard averagePace > 0 else { return "not available" }
        let minutes = Int(averagePace) / 60
        let seconds = Int(averagePace) % 60
        if minutes > 0 {
            return "\(minutes) minutes \(seconds) seconds"
        }
        return "\(seconds) seconds"
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
