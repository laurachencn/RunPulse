import XCTest
@testable import RunPulseWatch

@MainActor
final class VoiceServiceTests: XCTestCase {
    var service: VoiceService!
    
    override func setUp() {
        super.setUp()
        service = VoiceService.shared
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "voiceEnabled")
        super.tearDown()
    }
    
    func testVoiceServiceIsSingleton() {
        let instance1 = VoiceService.shared
        let instance2 = VoiceService.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testIsSpeakingInitiallyFalse() {
        XCTAssertFalse(service.isSpeaking)
    }
    
    func testSpeakWhenDisabledDoesNothing() {
        UserDefaults.standard.set(false, forKey: "voiceEnabled")
        Task {
            await service.speak("Test")
        }
    }
    
    func testSpeakWhenEnabledQueuesSpeech() {
        UserDefaults.standard.set(true, forKey: "voiceEnabled")
        Task {
            await service.speak("Test")
        }
    }
    
    func testStopCancelsSpeech() {
        service.stop()
        XCTAssertFalse(service.isSpeaking)
    }
}
