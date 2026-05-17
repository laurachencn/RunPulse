import Foundation

struct KilometerSplit: Codable, Identifiable, Hashable {
    let id: UUID
    let kilometerNumber: Int
    let duration: TimeInterval
    let averageHeartRate: Double
    let maxHeartRate: Double
    let minHeartRate: Double
    let pace: TimeInterval
    let distance: Double
    let calories: Double
    let timestamp: Date
    
    var paceString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
