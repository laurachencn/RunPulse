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
}
