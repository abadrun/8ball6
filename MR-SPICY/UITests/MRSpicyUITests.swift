import XCTest

final class MRSpicyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsMrSpicyAndNoAdUnlockCopy() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["MR. SPICY"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["WATCH AD TO UNLOCK"].exists)
        XCTAssertFalse(app.staticTexts["PAYMENT REQUIRED"].exists)
        XCTAssertFalse(app.staticTexts["SUBSCRIPTION REQUIRED"].exists)
    }

    func testOpenButtonKeepsOverlayAccessible() throws {
        let app = XCUIApplication()
        app.launch()

        let openButton = app.buttons["Open MR. SPICY"]
        if openButton.waitForExistence(timeout: 3) {
            openButton.tap()
        }

        XCTAssertTrue(app.staticTexts["MR. SPICY"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists || app.buttons["Language"].exists || app.buttons["Account"].exists)
    }
}
