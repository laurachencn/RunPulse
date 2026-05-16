import XCTest
@testable import RunPulseWatch

final class HeartRateMonitorTests: XCTestCase {
    var monitor: HeartRateMonitor!
    
    override func setUp() {
        super.setUp()
        monitor = HeartRateMonitor(alertThreshold: 171)
    }
    
    func testInitialState() {
        XCTAssertEqual(monitor.currentHeartRate, 0)
        XCTAssertFalse(monitor.isAlerting)
    }
    
    func testHeartRateBelowThreshold() {
        monitor.processHeartRate(150)
        XCTAssertEqual(monitor.currentHeartRate, 150)
        XCTAssertFalse(monitor.isAlerting)
    }
    
    func testHeartRateAboveThreshold() {
        monitor.processHeartRate(175)
        XCTAssertTrue(monitor.isAlerting)
    }
    
    func testAlertClearsWhenBelowThreshold() {
        monitor.processHeartRate(175)
        XCTAssertTrue(monitor.isAlerting)
        monitor.processHeartRate(160)
        XCTAssertFalse(monitor.isAlerting)
    }
    
    func testAverageHeartRate() {
        monitor.processHeartRate(140)
        monitor.processHeartRate(160)
        monitor.processHeartRate(150)
        XCTAssertEqual(monitor.averageHeartRate, 150.0, accuracy: 0.1)
    }
}
