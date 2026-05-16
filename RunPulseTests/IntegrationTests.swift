import XCTest
@testable import RunPulse
@testable import RunPulseWatch

final class IntegrationTests: XCTestCase {
    func testFullRunSessionFlow() {
        var session = RunSession.newSession()
        
        for km in 1...5 {
            let split = KilometerSplit(
                id: UUID(),
                kilometerNumber: km,
                duration: 300,
                averageHeartRate: 150 + Double(km) * 2,
                maxHeartRate: 160 + Double(km) * 2,
                minHeartRate: 140 + Double(km) * 2,
                pace: 300,
                distance: 1000,
                calories: 60,
                timestamp: Date().addingTimeInterval(Double(km) * 300)
            )
            session.splits.append(split)
        }
        
        session.totalDistance = 5000
        session.totalDuration = 1500
        session.averageHeartRate = 160
        session.maxHeartRate = 170
        session.averagePace = 300
        session.isCompleted = true
        
        XCTAssertEqual(session.totalDistanceKm, 5.0)
        XCTAssertEqual(session.durationString, "25:00")
        XCTAssertEqual(session.averagePaceString, "5:00")
        XCTAssertEqual(session.splits.count, 5)
    }
    
    func testHeartRateAlertIntegration() {
        let alertEngine = AlertEngine(threshold: 171)
        
        for hr in stride(from: 140, through: 180, by: 5) {
            alertEngine.checkHeartRate(Double(hr))
        }
        
        XCTAssertTrue(alertEngine.isAlerting)
        XCTAssertEqual(alertEngine.alertCount, 1)
    }
    
    func testUserProfileCalculations() {
        let profile = UserProfile(
            id: UUID(),
            age: 40,
            weight: 80,
            height: 180,
            restingHeartRate: 65,
            maxHeartRateOverride: nil
        )
        
        XCTAssertEqual(profile.calculatedMaxHeartRate, 180)
        XCTAssertEqual(profile.alertThresholdHeartRate, 162)
    }
}
