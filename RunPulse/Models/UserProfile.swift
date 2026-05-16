import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var age: Int
    var weight: Double
    var height: Double
    var restingHeartRate: Int
    var maxHeartRateOverride: Int?
    
    var calculatedMaxHeartRate: Int {
        220 - age
    }
    
    var alertThresholdHeartRate: Int {
        Int(Double(maxHeartRate) * 0.90)
    }
    
    var maxHeartRate: Int {
        maxHeartRateOverride ?? calculatedMaxHeartRate
    }
    
    static var `default`: UserProfile {
        UserProfile(
            id: UUID(),
            age: 30,
            weight: 70.0,
            height: 175.0,
            restingHeartRate: 60,
            maxHeartRateOverride: nil
        )
    }
}
