import XCTest

final class LaunchFlowTests: XCTestCase {
    func testTurkishTabsAreVisible() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Ana Sayfa"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabBars.buttons["Oluştur"].exists)
        XCTAssertTrue(app.tabBars.buttons["Favoriler"].exists)
        XCTAssertTrue(app.tabBars.buttons["Ayarlar"].exists)
    }

    func testHomePassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Ana Sayfa"].waitForExistence(timeout: 8))
        try app.performAccessibilityAudit()
    }
}
