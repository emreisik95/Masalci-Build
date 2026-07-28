import XCTest

@MainActor
final class PrimaryFlowTests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Ana Sayfa"].waitForExistence(timeout: 8))
        return app
    }

    func testFeaturedStoryOpensDetail() {
        let app = launchApp()
        let featuredStory = app.descendants(matching: .any)["ana-sayfa.one-cikan-masal"]

        XCTAssertTrue(featuredStory.waitForExistence(timeout: 5))
        featuredStory.tap()

        XCTAssertTrue(app.buttons["Geri dön"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Favorilerden çıkar"].exists)
        XCTAssertTrue(app.staticTexts["Ay Işığını Arayan Minik Tavşan"].exists)
        keepScreenshot(of: app, named: "04-masal-ayrintisi")
    }

    func testStoryCanBeCreatedFromPreviewBackend() {
        let app = launchApp()
        app.tabBars.buttons["Oluştur"].tap()

        XCTAssertTrue(app.staticTexts["Masal Oluştur"].waitForExistence(timeout: 5))
        keepScreenshot(of: app, named: "02-masal-olustur")
        let prompt = app.textViews["Masal fikri"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        prompt.tap()
        prompt.typeText("Ay ışığında yolunu bulan minik bir tavşan için sakin bir uyku masalı.")

        let createButton = app.buttons["olustur.baslat"]
        XCTAssertTrue(createButton.isEnabled)
        createButton.tap()

        XCTAssertTrue(app.buttons["Geri dön"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Ay Işığını Arayan Minik Tavşan"].exists)
    }

    func testFavoritesOpenAStory() {
        let app = launchApp()
        app.tabBars.buttons["Favoriler"].tap()

        let favorite = app.descendants(matching: .any)["masal-karti.mercan-bahcesi"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 5))
        keepScreenshot(of: app, named: "03-favoriler")
        favorite.tap()

        XCTAssertTrue(app.buttons["Geri dön"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Mercan Bahçesinin Şarkısı"].exists)
    }

    func testParentGateAndPrivacyAreReachable() {
        let app = launchApp()
        app.tabBars.buttons["Ayarlar"].tap()

        let privacyButton = app.buttons["Gizlilik ve çocuk güvenliği"]
        XCTAssertTrue(privacyButton.waitForExistence(timeout: 5))
        privacyButton.tap()
        XCTAssertTrue(app.navigationBars["Gizlilik"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Çocuk güvenliği"].exists)
        app.buttons["Bitti"].tap()

        let parentButton = app.buttons["Ebeveyn alanını aç"]
        XCTAssertTrue(parentButton.waitForExistence(timeout: 5))
        parentButton.tap()

        let answer = app.textFields["Ebeveyn doğrulama sonucu"]
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        answer.tap()
        answer.typeText("12")
        app.buttons["Alanı Aç"].tap()

        XCTAssertTrue(app.buttons["Premium'u keşfet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Hesabı sil"].exists)
    }

    func testCreateScreenPassesAccessibilityAudit() throws {
        let app = launchApp()
        app.tabBars.buttons["Oluştur"].tap()
        XCTAssertTrue(app.staticTexts["Masal Oluştur"].waitForExistence(timeout: 5))
        try audit(app)
    }

    func testFavoritesScreenPassesAccessibilityAudit() throws {
        let app = launchApp()
        app.tabBars.buttons["Favoriler"].tap()
        XCTAssertTrue(app.staticTexts["Favoriler"].waitForExistence(timeout: 5))
        try audit(app)
    }

    func testSettingsScreenPassesAccessibilityAudit() throws {
        let app = launchApp()
        app.tabBars.buttons["Ayarlar"].tap()
        XCTAssertTrue(app.navigationBars["Ayarlar"].waitForExistence(timeout: 5))
        try audit(app)
    }

    private func audit(_ app: XCUIApplication) throws {
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
