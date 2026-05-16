import XCTest
@testable import RunPulseWatch

@MainActor
final class AlertEngineTests: XCTestCase {
    var engine: AlertEngine!
    
    override func setUp() {
        super.setUp()
        engine = AlertEngine(threshold: 171)
    }
    
    func testInitialState() {
        XCTAssertFalse(engine.isAlerting)
    }
    
    func testAlertTriggersAboveThreshold() {
        engine.checkHeartRate(175)
        XCTAssertTrue(engine.isAlerting)
    }
    
    func testNoAlertBelowThreshold() {
        engine.checkHeartRate(160)
        XCTAssertFalse(engine.isAlerting)
    }
    
    func testAlertClearsWithHysteresis() {
        engine.checkHeartRate(175)
        XCTAssertTrue(engine.isAlerting)
        engine.checkHeartRate(167)
        XCTAssertTrue(engine.isAlerting)
        engine.checkHeartRate(165)
        XCTAssertFalse(engine.isAlerting)
    }
    
    func testAlertCount() {
        engine.checkHeartRate(175)
        engine.checkHeartRate(160)
        engine.checkHeartRate(175)
        XCTAssertEqual(engine.alertCount, 2)
    }
}
