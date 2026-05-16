import XCTest
@testable import RunPulse

@MainActor
final class StorageManagerTests: XCTestCase {
    var manager: StorageManager!
    var testDirURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        manager = StorageManager()
        try await Task.sleep(nanoseconds: 100_000_000)
        let fm = FileManager.default
        testDirURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("RunPulseRuns")
        if fm.fileExists(atPath: testDirURL.path) {
            try? fm.removeItem(at: testDirURL)
        }
    }
    
    override func tearDown() async throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: testDirURL.path) {
            try? fm.removeItem(at: testDirURL)
        }
        try await super.tearDown()
    }
    
    func testSaveAndLoadSingleRun() async {
        let run = RunSession.newSession()
        await manager.saveRun(run)
        try await Task.sleep(nanoseconds: 50_000_000)
        await manager.loadRuns()
        XCTAssertEqual(manager.savedRuns.count, 1)
        XCTAssertEqual(manager.savedRuns.first?.id, run.id)
    }
    
    func testLoadEmptyStorage() async {
        await manager.loadRuns()
        XCTAssertTrue(manager.savedRuns.isEmpty)
    }
    
    func testDeleteRun() async {
        let run = RunSession.newSession()
        await manager.saveRun(run)
        try await Task.sleep(nanoseconds: 50_000_000)
        await manager.deleteRun(run)
        try await Task.sleep(nanoseconds: 50_000_000)
        await manager.loadRuns()
        XCTAssertTrue(manager.savedRuns.isEmpty)
    }
    
    func testMultipleRunsSortedByDate() async {
        var run1 = RunSession.newSession()
        run1.startDate = Date().addingTimeInterval(-3600)
        var run2 = RunSession.newSession()
        run2.startDate = Date()
        
        await manager.saveRun(run1)
        try await Task.sleep(nanoseconds: 50_000_000)
        await manager.saveRun(run2)
        try await Task.sleep(nanoseconds: 50_000_000)
        await manager.loadRuns()
        
        XCTAssertEqual(manager.savedRuns.count, 2)
        XCTAssertEqual(manager.savedRuns.first?.id, run2.id)
        XCTAssertEqual(manager.savedRuns.last?.id, run1.id)
    }
    
    func testSaveOverwritesExisting() async {
        let run = RunSession.newSession()
        await manager.saveRun(run)
        try await Task.sleep(nanoseconds: 50_000_000)
        await manager.saveRun(run)
        try await Task.sleep(nanoseconds: 50_000_000)
        await manager.loadRuns()
        XCTAssertEqual(manager.savedRuns.count, 1)
    }
}
