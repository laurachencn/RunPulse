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
}
