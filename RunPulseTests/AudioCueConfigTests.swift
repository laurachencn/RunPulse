import XCTest
@testable import RunPulse

@MainActor
final class AudioCueConfigTests: XCTestCase {
    
    func testDefaultConfig() {
        let config = AudioCueConfig.default
        XCTAssertTrue(config.voiceEnabled)
        XCTAssertTrue(config.announcePace)
        XCTAssertTrue(config.announceHeartRate)
        XCTAssertTrue(config.announceDistance)
        XCTAssertFalse(config.announceCalories)
        XCTAssertEqual(config.distanceInterval, .km1)
        XCTAssertEqual(config.timeInterval, .off)
    }
    
    func testAudioCueConfigCodable() {
        var config = AudioCueConfig.default
        config.announceCalories = true
        config.distanceInterval = .km2
        config.timeInterval = .min5
        
        let data = try! JSONEncoder().encode(config)
        let decoded = try! JSONDecoder().decode(AudioCueConfig.self, from: data)
        
        XCTAssertEqual(decoded.announcePace, true)
        XCTAssertEqual(decoded.announceHeartRate, true)
        XCTAssertEqual(decoded.announceDistance, true)
        XCTAssertEqual(decoded.announceCalories, true)
        XCTAssertEqual(decoded.distanceInterval, .km2)
        XCTAssertEqual(decoded.timeInterval, .min5)
    }
    
    func testDistanceIntervalRawValues() {
        XCTAssertEqual(DistanceInterval.kmHalf.rawValue, 0.5)
        XCTAssertEqual(DistanceInterval.km1.rawValue, 1.0)
        XCTAssertEqual(DistanceInterval.km2.rawValue, 2.0)
        XCTAssertEqual(DistanceInterval.km5.rawValue, 5.0)
    }
    
    func testTimeIntervalRawValues() {
        XCTAssertEqual(TimeIntervalInterval.off.rawValue, 0)
        XCTAssertEqual(TimeIntervalInterval.min1.rawValue, 60)
        XCTAssertEqual(TimeIntervalInterval.min5.rawValue, 300)
        XCTAssertEqual(TimeIntervalInterval.min10.rawValue, 600)
        XCTAssertEqual(TimeIntervalInterval.min15.rawValue, 900)
    }
}
