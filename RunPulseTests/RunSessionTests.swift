import XCTest
@testable import RunPulse

@MainActor
final class RunSessionTests: XCTestCase {
    func testNewSessionHasCorrectDefaults() {
        let session = RunSession.newSession()
        XCTAssertNotNil(session.id)
        XCTAssertNil(session.endDate)
        XCTAssertEqual(session.totalDuration, 0)
        XCTAssertEqual(session.totalDistance, 0)
        XCTAssertEqual(session.totalCalories, 0)
        XCTAssertEqual(session.averageHeartRate, 0)
        XCTAssertEqual(session.maxHeartRate, 0)
        XCTAssertEqual(session.averagePace, 0)
        XCTAssertTrue(session.splits.isEmpty)
        XCTAssertFalse(session.isCompleted)
    }
    
    func testDurationStringWithHours() {
        var session = RunSession.newSession()
        session.totalDuration = 5025
        XCTAssertEqual(session.durationString, "1:23:45")
    }
    
    func testDurationStringWithoutHours() {
        var session = RunSession.newSession()
        session.totalDuration = 1500
        XCTAssertEqual(session.durationString, "25:00")
    }
    
    func testAveragePaceString() {
        var session = RunSession.newSession()
        session.averagePace = 365
        XCTAssertEqual(session.averagePaceString, "6:05")
    }
    
    func testRunSessionCodableRoundTrip() {
        var session = RunSession.newSession()
        session.endDate = Date()
        session.totalDuration = 1800
        session.totalDistance = 5000
        session.averageHeartRate = 155
        session.maxHeartRate = 175
        session.averagePace = 360
        session.isCompleted = true
        
        let data = try! JSONEncoder().encode(session)
        let decoded = try! JSONDecoder().decode(RunSession.self, from: data)
        
        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.totalDuration, 1800)
        XCTAssertEqual(decoded.totalDistance, 5000)
        XCTAssertEqual(decoded.averageHeartRate, 155)
        XCTAssertEqual(decoded.isCompleted, true)
    }
}
