import XCTest
@testable import RunPulseWatch

@MainActor
final class WorkoutManagerTests: XCTestCase {
    var workoutManager: WorkoutManager!
    
    override func setUp() {
        super.setUp()
        workoutManager = WorkoutManager()
    }
    
    override func tearDown() {
        workoutManager = nil
        super.tearDown()
    }
    
    func testInitialStateIsNotRunning() {
        XCTAssertEqual(workoutManager.runState.state, .notStarted)
    }
    
    func testPaceCalculation() {
        let pace = workoutManager.calculatePace(duration: 300, distance: 1000)
        XCTAssertEqual(pace, 300.0, accuracy: 0.1)
    }
    
    func testDistanceToKilometers() {
        XCTAssertEqual(workoutManager.metersToKilometers(1500), 1.5)
    }
    
    func testCurrentKilometerFromDistance() {
        XCTAssertEqual(workoutManager.currentKilometer(for: 2500), 3)
    }
}
