import XCTest
@testable import RunPulseWatch

@MainActor
final class AudioCueManagerTests: XCTestCase {
    
    var manager: AudioCueManager!
    var config: AudioCueConfig!
    
    override func setUp() {
        super.setUp()
        config = AudioCueConfig.default
        manager = AudioCueManager(config: config)
    }
    
    func testInitialState() {
        XCTAssertEqual(manager.totalDistanceAnnounced, 0)
        XCTAssertEqual(manager.lastTimeAnnouncement, nil)
    }
    
    func testNoCueWhenVoiceDisabled() {
        config.voiceEnabled = false
        manager.config = config
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        XCTAssertTrue(manager.pendingCues.isEmpty)
    }
    
    func testDistanceCueAtFirstKilometer() {
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        XCTAssertEqual(manager.pendingCues.count, 1)
        XCTAssertTrue(manager.pendingCues.first?.contains("1 kilometer") == true)
    }
    
    func testDistanceCueAtSecondKilometer() {
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        _ = manager.pendingCues
        manager.resetCues()
        
        manager.updateMetrics(
            distance: 2000,
            pace: 310,
            heartRate: 155,
            calories: 200,
            currentTime: Date()
        )
        XCTAssertEqual(manager.pendingCues.count, 1)
        XCTAssertTrue(manager.pendingCues.first?.contains("2 kilometers") == true)
    }
    
    func testNoDistanceCueBeforeInterval() {
        manager.updateMetrics(
            distance: 500,
            pace: 300,
            heartRate: 150,
            calories: 50,
            currentTime: Date()
        )
        XCTAssertTrue(manager.pendingCues.isEmpty)
    }
    
    func testTimeCueAtInterval() {
        config.timeInterval = .min5
        manager.config = config
        
        let startTime = Date()
        let fiveMinutesLater = startTime.addingTimeInterval(300)
        
        manager.updateMetrics(
            distance: 500,
            pace: 300,
            heartRate: 150,
            calories: 50,
            currentTime: fiveMinutesLater
        )
        XCTAssertEqual(manager.pendingCues.count, 1)
    }
    
    func testNoTimeCueWhenOff() {
        config.timeInterval = .off
        manager.config = config
        
        let startTime = Date()
        let tenMinutesLater = startTime.addingTimeInterval(600)
        
        manager.updateMetrics(
            distance: 500,
            pace: 300,
            heartRate: 150,
            calories: 50,
            currentTime: tenMinutesLater
        )
        XCTAssertTrue(manager.pendingCues.isEmpty)
    }
    
    func testMultipleCuesWhenBothIntervalsFire() {
        config.timeInterval = .min5
        manager.config = config
        
        let startTime = Date()
        let fiveMinutesLater = startTime.addingTimeInterval(300)
        
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: fiveMinutesLater
        )
        XCTAssertGreaterThanOrEqual(manager.pendingCues.count, 2)
    }
    
    func testCueContainsEnabledMetrics() {
        config.announceCalories = true
        manager.config = config
        
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        let cue = manager.pendingCues.first ?? ""
        XCTAssertTrue(cue.contains("pace"))
        XCTAssertTrue(cue.contains("heart rate"))
        XCTAssertTrue(cue.contains("calories"))
    }
    
    func testCueExcludesDisabledMetrics() {
        config.announcePace = false
        manager.config = config
        
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        let cue = manager.pendingCues.first ?? ""
        XCTAssertFalse(cue.contains("pace"))
    }
    
    func testResetClearsAnnouncedState() {
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        manager.reset()
        XCTAssertEqual(manager.totalDistanceAnnounced, 0)
        XCTAssertEqual(manager.lastTimeAnnouncement, nil)
        XCTAssertTrue(manager.pendingCues.isEmpty)
    }
}
