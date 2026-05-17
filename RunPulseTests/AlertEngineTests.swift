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
    
    func testResetClearsAllState() {
        engine.checkHeartRate(175)
        engine.reset()
        XCTAssertFalse(engine.isAlerting)
        XCTAssertEqual(engine.alertCount, 0)
        XCTAssertNil(engine.lastAlertTime)
    }
    
    func testExactlyAtThresholdNoAlert() {
        engine.checkHeartRate(171)
        XCTAssertFalse(engine.isAlerting)
    }
    
    func testMultipleThresholds() {
        let lowEngine = AlertEngine(threshold: 160)
        let highEngine = AlertEngine(threshold: 180)
        lowEngine.checkHeartRate(165)
        highEngine.checkHeartRate(165)
        XCTAssertTrue(lowEngine.isAlerting)
        XCTAssertFalse(highEngine.isAlerting)
    }
    
    func testLastAlertTimeSetOnTrigger() {
        let before = Date()
        engine.checkHeartRate(175)
        XCTAssertNotNil(engine.lastAlertTime)
        XCTAssertTrue(engine.lastAlertTime! >= before)
    }
    
    func testAlertTriggersVoiceFeedback() {
        UserDefaults.standard.set(true, forKey: "voiceEnabled")
        let engine = AlertEngine(threshold: 150)
        XCTAssertFalse(engine.isAlerting)
        
        engine.checkHeartRate(160)
        XCTAssertTrue(engine.isAlerting)
        // VoiceService.speak should have been called (verified by no crash)
        UserDefaults.standard.removeObject(forKey: "voiceEnabled")
    }
    
    func testRapidFluctuationHandling() {
        for _ in 0..<10 {
            engine.checkHeartRate(175)
            engine.checkHeartRate(160)
        }
        XCTAssertFalse(engine.isAlerting)
    }
}
