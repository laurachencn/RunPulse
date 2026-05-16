import XCTest
@testable import RunPulseWatch

@MainActor
final class PaceTrackerTests: XCTestCase {
    var tracker: PaceTracker!
    
    override func setUp() {
        super.setUp()
        tracker = PaceTracker()
    }
    
    func testInitialState() {
        XCTAssertEqual(tracker.currentPace, 0)
        XCTAssertEqual(tracker.totalDistance, 0)
    }
    
    func testPaceForExactKilometer() {
        tracker.updateDistance(1000, at: Date().addingTimeInterval(300))
        XCTAssertEqual(tracker.currentPace, 300.0, accuracy: 0.1)
    }
    
    func testPaceForHalfKilometer() {
        tracker.updateDistance(500, at: Date().addingTimeInterval(150))
        XCTAssertEqual(tracker.currentPace, 300.0, accuracy: 0.1)
    }
    
    func testKilometerCompletion() {
        tracker.updateDistance(1000, at: Date().addingTimeInterval(300))
        XCTAssertNotNil(tracker.lastSplit)
        XCTAssertEqual(tracker.lastSplit?.kilometerNumber, 1)
    }
    
    func testMultipleKilometers() {
        tracker.updateDistance(1000, at: Date().addingTimeInterval(300))
        tracker.updateDistance(2000, at: Date().addingTimeInterval(600))
        XCTAssertEqual(tracker.completedKilometers, 2)
    }
    
    func testPaceStringFormatting() {
        XCTAssertEqual(PaceTracker.formatPace(300), "5:00")
        XCTAssertEqual(PaceTracker.formatPace(245), "4:05")
        XCTAssertEqual(PaceTracker.formatPace(3661), "61:01")
    }
    
    func testResetClearsAllState() {
        tracker.updateDistance(1000, at: Date().addingTimeInterval(300))
        tracker.reset()
        XCTAssertEqual(tracker.currentPace, 0)
        XCTAssertEqual(tracker.totalDistance, 0)
        XCTAssertEqual(tracker.completedKilometers, 0)
        XCTAssertNil(tracker.lastSplit)
        XCTAssertTrue(tracker.splits.isEmpty)
    }
    
    func testZeroDistanceNoCrash() {
        tracker.updateDistance(0, at: Date())
        XCTAssertEqual(tracker.currentPace, 0)
        XCTAssertFalse(tracker.currentPace.isNaN)
    }
    
    func testSmallDistanceIncrement() {
        tracker.updateDistance(50, at: Date().addingTimeInterval(10))
        XCTAssertEqual(tracker.completedKilometers, 0)
        XCTAssertNil(tracker.lastSplit)
    }
    
    func testPartialKilometerAccumulation() {
        tracker.updateDistance(400, at: Date().addingTimeInterval(120))
        tracker.updateDistance(1000, at: Date().addingTimeInterval(300))
        XCTAssertEqual(tracker.completedKilometers, 1)
        XCTAssertEqual(tracker.lastSplit?.kilometerNumber, 1)
    }
    
    func testThreeKilometersSequential() {
        tracker.updateDistance(1000, at: Date().addingTimeInterval(300))
        tracker.updateDistance(2000, at: Date().addingTimeInterval(600))
        tracker.updateDistance(3000, at: Date().addingTimeInterval(900))
        XCTAssertEqual(tracker.completedKilometers, 3)
        XCTAssertEqual(tracker.splits.count, 3)
    }
    
    func testPaceStringZero() {
        XCTAssertEqual(PaceTracker.formatPace(0), "0:00")
    }
    
    func testSplitContainsCorrectData() {
        tracker.updateDistance(1000, at: Date().addingTimeInterval(300))
        let split = tracker.lastSplit!
        XCTAssertEqual(split.kilometerNumber, 1)
        XCTAssertEqual(split.duration, 300, accuracy: 0.1)
        XCTAssertEqual(split.pace, 300, accuracy: 0.1)
        XCTAssertEqual(split.distance, 1000)
    }
}
