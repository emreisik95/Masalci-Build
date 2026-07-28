import XCTest

@MainActor
final class LaunchFlowTests: XCTestCase {
    func testTurkishTabsAreVisible() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Ana Sayfa"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabBars.buttons["Oluştur"].exists)
        XCTAssertTrue(app.tabBars.buttons["Favoriler"].exists)
        XCTAssertTrue(app.tabBars.buttons["Ayarlar"].exists)
        keepScreenshot(of: app, named: "01-ana-sayfa")
    }

    func testHomePassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Ana Sayfa"].waitForExistence(timeout: 8))
        try app.performAccessibilityAudit(
            for: [
                .elementDetection,
                .hitRegion,
                .sufficientElementDescription,
                .trait,
            ]
        )
    }

    private func keepScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
