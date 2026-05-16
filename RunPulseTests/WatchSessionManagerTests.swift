import XCTest
@testable import RunPulse

@MainActor
final class WatchSessionManagerTests: XCTestCase {
    var manager: WatchSessionManager!
    
    override func setUp() {
        super.setUp()
        manager = WatchSessionManager()
    }
    
    func testInitialState() {
        XCTAssertFalse(manager.isPaired)
        XCTAssertFalse(manager.isReachable)
    }
    
    func testRunSessionEncoding() {
        let session = RunSession.newSession()
        let data = try? JSONEncoder().encode(session)
        XCTAssertNotNil(data)
        
        let decoded = try? JSONDecoder().decode(RunSession.self, from: data!)
        XCTAssertEqual(decoded?.id, session.id)
    }
}
