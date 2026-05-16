import Foundation
import HealthKit

@MainActor
final class HeartRateMonitor: ObservableObject {
    @Published var currentHeartRate: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var maxHeartRate: Double = 0
    @Published var minHeartRate: Double = .infinity
    @Published var isAlerting: Bool = false
    
    private var heartRates: [Double] = []
    private let alertThreshold: Int
    
    init(alertThreshold: Int) {
        self.alertThreshold = alertThreshold
    }
    
    func processHeartRate(_ heartRate: Double) {
        currentHeartRate = heartRate
        heartRates.append(heartRate)
        
        averageHeartRate = heartRates.reduce(0, +) / Double(heartRates.count)
        maxHeartRate = heartRates.max() ?? 0
        minHeartRate = heartRates.min() ?? .infinity
        
        if heartRate > Double(alertThreshold) && !isAlerting {
            isAlerting = true
        } else if heartRate < Double(alertThreshold) - 5 && isAlerting {
            isAlerting = false
        }
    }
    
    func reset() {
        currentHeartRate = 0
        averageHeartRate = 0
        maxHeartRate = 0
        minHeartRate = .infinity
        isAlerting = false
        heartRates.removeAll()
    }
    
    func getHeartRateSamples() -> [Double] {
        Array(heartRates)
    }
}
