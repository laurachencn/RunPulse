import XCTest
@testable import RunPulseWatch

@MainActor
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
    
    func testMaxHeartRateTracksCorrectly() {
        monitor.processHeartRate(140)
        monitor.processHeartRate(160)
        monitor.processHeartRate(150)
        XCTAssertEqual(monitor.maxHeartRate, 160.0, accuracy: 0.1)
    }
    
    func testMinHeartRateTracksCorrectly() {
        monitor.processHeartRate(150)
        monitor.processHeartRate(130)
        monitor.processHeartRate(140)
        XCTAssertEqual(monitor.minHeartRate, 130.0, accuracy: 0.1)
    }
    
    func testResetClearsAllState() {
        monitor.processHeartRate(150)
        monitor.reset()
        XCTAssertEqual(monitor.currentHeartRate, 0)
        XCTAssertEqual(monitor.averageHeartRate, 0)
        XCTAssertEqual(monitor.maxHeartRate, 0)
        XCTAssertEqual(monitor.minHeartRate, .infinity)
        XCTAssertFalse(monitor.isAlerting)
        XCTAssertEqual(monitor.getHeartRateSamples().count, 0)
    }
    
    func testGetHeartRateSamplesReturnsAllValues() {
        monitor.processHeartRate(140)
        monitor.processHeartRate(150)
        monitor.processHeartRate(160)
        let samples = monitor.getHeartRateSamples()
        XCTAssertEqual(samples, [140, 150, 160])
    }
    
    func testZeroHeartRate() {
        monitor.processHeartRate(0)
        XCTAssertEqual(monitor.currentHeartRate, 0)
        XCTAssertEqual(monitor.averageHeartRate, 0)
        XCTAssertFalse(monitor.isAlerting)
    }
    
    func testExtremeHeartRate() {
        monitor.processHeartRate(220)
        XCTAssertEqual(monitor.currentHeartRate, 220)
        XCTAssertEqual(monitor.maxHeartRate, 220)
    }
    
    func testAlertAtExactThreshold() {
        monitor.processHeartRate(171)
        XCTAssertFalse(monitor.isAlerting)
    }
    
    func testMultipleAlertCycles() {
        monitor.processHeartRate(175)
        XCTAssertTrue(monitor.isAlerting)
        monitor.processHeartRate(160)
        XCTAssertFalse(monitor.isAlerting)
        monitor.processHeartRate(180)
        XCTAssertTrue(monitor.isAlerting)
        monitor.processHeartRate(160)
        XCTAssertFalse(monitor.isAlerting)
    }
}
