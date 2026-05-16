import XCTest
@testable import RunPulseWatch

@MainActor
final class WatchRunStateTests: XCTestCase {
    func testIdleStateDefaults() {
        let state = WatchRunState.idle
        XCTAssertEqual(state.state, .notStarted)
        XCTAssertEqual(state.currentHeartRate, 0)
        XCTAssertEqual(state.currentDistance, 0)
        XCTAssertEqual(state.currentDuration, 0)
        XCTAssertEqual(state.currentKilometer, 0)
        XCTAssertEqual(state.alertThreshold, 171)
        XCTAssertFalse(state.isAlerting)
        XCTAssertNil(state.lastSplit)
        XCTAssertEqual(state.totalCalories, 0)
    }
    
    func testRunStateRawValues() {
        XCTAssertEqual(RunState.notStarted.rawValue, "notStarted")
        XCTAssertEqual(RunState.running.rawValue, "running")
        XCTAssertEqual(RunState.paused.rawValue, "paused")
        XCTAssertEqual(RunState.completed.rawValue, "completed")
    }
    
    func testWatchRunStateCodable() {
        var state = WatchRunState.idle
        state.state = .running
        state.currentHeartRate = 155
        state.currentDistance = 2500
        state.currentKilometer = 3
        
        let data = try! JSONEncoder().encode(state)
        let decoded = try! JSONDecoder().decode(WatchRunState.self, from: data)
        
        XCTAssertEqual(decoded.state, .running)
        XCTAssertEqual(decoded.currentHeartRate, 155)
        XCTAssertEqual(decoded.currentDistance, 2500)
        XCTAssertEqual(decoded.currentKilometer, 3)
    }
}
