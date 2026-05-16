import XCTest

final class RunPulseUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testLaunchAndNavigate() throws {
        XCTAssertTrue(app.staticTexts["Dashboard"].exists || app.staticTexts["RunPulse"].exists)
        
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            XCTAssertTrue(app.staticTexts["Profile"].exists || app.staticTexts["Settings"].exists)
        }
    }
    
    func testSettingsViewElements() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            XCTAssertTrue(app.staticTexts["Age"].exists || app.steppers.count > 0)
        }
    }
}
