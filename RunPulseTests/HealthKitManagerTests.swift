import XCTest
@testable import RunPulse

@MainActor
final class HealthKitManagerTests: XCTestCase {
    func testHealthKitAuthorizationStatusReturnsCorrectValue() {
        let manager = HealthKitManager()
        XCTAssertFalse(manager.isAuthorized)
    }
    
    func testMaxHeartRateCalculation() {
        let profile = UserProfile.default
        XCTAssertEqual(profile.calculatedMaxHeartRate, 190)
    }
    
    func testAlertThresholdCalculation() {
        let profile = UserProfile.default
        XCTAssertEqual(profile.alertThresholdHeartRate, 171)
    }
    
    func testCustomMaxHROverride() {
        let profile = UserProfile(
            id: UUID(),
            age: 30,
            weight: 70,
            height: 175,
            restingHeartRate: 60,
            maxHeartRateOverride: 185
        )
        XCTAssertEqual(profile.maxHeartRate, 185)
    }
    
    func testAlertThresholdWithCustomMaxHR() {
        let profile = UserProfile(
            id: UUID(),
            age: 30,
            weight: 70,
            height: 175,
            restingHeartRate: 60,
            maxHeartRateOverride: 200
        )
        XCTAssertEqual(profile.alertThresholdHeartRate, 180)
    }
    
    func testExtremeAge() {
        let young = UserProfile(id: UUID(), age: 18, weight: 70, height: 175, restingHeartRate: 60, maxHeartRateOverride: nil)
        let old = UserProfile(id: UUID(), age: 100, weight: 70, height: 175, restingHeartRate: 60, maxHeartRateOverride: nil)
        XCTAssertEqual(young.calculatedMaxHeartRate, 202)
        XCTAssertEqual(old.calculatedMaxHeartRate, 120)
    }
    
    func testDefaultProfileValues() {
        let profile = UserProfile.default
        XCTAssertEqual(profile.age, 30)
        XCTAssertEqual(profile.weight, 70.0)
        XCTAssertEqual(profile.height, 175.0)
        XCTAssertEqual(profile.restingHeartRate, 60)
        XCTAssertNil(profile.maxHeartRateOverride)
    }
}
