import XCTest

/// Takes the screenshots for the App Store. Not part of the normal test runs (see the test plans);
/// start it with `scripts/screenshots.sh`, which runs it on the required devices and collects the images.
/// The app shows a simulated amplifier, so the pictures always look the same.
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        #if os(macOS)
        throw XCTSkip("Screenshots are taken on iPhone and iPad")
        #endif
        continueAfterFailure = false
        app = XCUIApplication()
        // Every option comes with a value, see OneRemoteUITests
        app.launchArguments += ["-simulated-amplifier", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                                "-ApplePersistenceIgnoreState", "YES"]
    }

    private func launch(paired: Bool) {
        if paired { app.launchArguments += ["-simulated-paired", "YES"] }
        app.launch()
    }

    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Waits until the splash image and the blinking of the LEDs are over, then saves the screen
    private func shoot(_ name: String) {
        Thread.sleep(forTimeInterval: 2.5)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testScreenshots() {
        // 1. Search with the amplifier found
        launch(paired: false)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "foundDevice").firstMatch
            .waitForExistence(timeout: 15))
        shoot("04-Search")
        app.terminate()

        // 2. Controls
        app.launchArguments += ["-simulated-paired", "YES"]
        app.launch()
        let volume = element("volumeKnob")
        XCTAssertTrue(volume.waitForExistence(timeout: 15))
        shoot("01-Controls")

        // 3. Muted
        volume.tap()
        expectation(for: NSPredicate(format: "value == 'Muted'"), evaluatedWith: volume)
        waitForExpectations(timeout: 10)
        shoot("02-Muted")
        volume.tap()

        // 4. Settings
        app.buttons["Settings"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2.1'")).firstMatch
            .waitForExistence(timeout: 10))
        shoot("03-Settings")
    }
}
