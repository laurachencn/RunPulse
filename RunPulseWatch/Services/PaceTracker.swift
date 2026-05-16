import Foundation

@MainActor
final class PaceTracker: ObservableObject {
    @Published var currentPace: TimeInterval = 0
    @Published var totalDistance: Double = 0
    @Published var completedKilometers: Int = 0
    @Published var lastSplit: KilometerSplit?
    @Published var splits: [KilometerSplit] = []
    
    private var currentKilometerDistance: Double = 0
    private var currentKilometerStartTime: Date = Date()
    private var lastLocationDate: Date = Date()
    
    static func formatPace(_ pace: TimeInterval) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func updateDistance(_ distance: Double, at date: Date) {
        let delta = distance - totalDistance
        totalDistance = distance
        currentKilometerDistance += delta
        lastLocationDate = date
        
        let kmDuration = date.timeIntervalSince(currentKilometerStartTime)
        if currentKilometerDistance > 0 {
            let km = currentKilometerDistance / 1000.0
            currentPace = kmDuration / km
        }
        
        while currentKilometerDistance >= 1000 {
            completeKilometer(at: date)
        }
    }
    
    private func completeKilometer(at date: Date) {
        let kmDuration = date.timeIntervalSince(currentKilometerStartTime)
        let kmNumber = splits.count + 1
        
        let split = KilometerSplit(
            id: UUID(),
            kilometerNumber: kmNumber,
            duration: kmDuration,
            averageHeartRate: 0,
            maxHeartRate: 0,
            minHeartRate: 0,
            pace: kmDuration,
            distance: 1000,
            calories: 0,
            timestamp: date
        )
        
        splits.append(split)
        lastSplit = split
        completedKilometers = kmNumber
        
        currentKilometerDistance -= 1000
        currentKilometerStartTime = date
    }
    
    func reset() {
        currentPace = 0
        totalDistance = 0
        completedKilometers = 0
        lastSplit = nil
        splits.removeAll()
        currentKilometerDistance = 0
        currentKilometerStartTime = Date()
    }
}
