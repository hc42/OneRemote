import XCTest

/// End-to-end tests of the app against a simulated amplifier (no Bluetooth, no hardware).
/// The app is started with `-simulated-amplifier`, which only exists in debug builds.
final class OneRemoteUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // The texts below are the English ones
        app.launchArguments += ["-simulated-amplifier", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    }

    private func launch(paired: Bool) {
        if paired { app.launchArguments.append("-simulated-paired") }
        app.launch()
        #if os(macOS)
        app.activate()
        #endif
    }

    private func knob(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Waits for an element; on failure the element tree is attached to the report
    private func waitFor(_ element: XCUIElement, _ what: String, timeout: TimeInterval = 15,
                         file: StaticString = #filePath, line: UInt = #line) {
        if !element.waitForExistence(timeout: timeout) {
            let tree = String(app.debugDescription.prefix(1500))
            XCTFail("Not found: \(what). App state \(app.state.rawValue) (4 = running in the foreground), windows: \(app.windows.count). Visible elements:\n\(tree)", file: file, line: line)
        }
    }

    private func value(of element: XCUIElement) -> String {
        element.value as? String ?? ""
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: Tests

    func testPairedStartShowsTheControls() {
        launch(paired: true)
        let volume = knob("volumeKnob")
        waitFor(volume, "volume knob")
        XCTAssertTrue(knob("inputKnob").exists)
        // The simulated amplifier starts on 40 (-50 dB) with the USB input
        XCTAssertTrue(NSPredicate(format: "value CONTAINS '50 dB'")
            .evaluate(with: volume), "Volume was: \(value(of: volume))")
        XCTAssertEqual(value(of: knob("inputKnob")), "USB")
        screenshot("Controls")
    }

    func testTappingTheVolumeKnobMutesAndUnmutes() {
        launch(paired: true)
        let volume = knob("volumeKnob")
        waitFor(volume, "volume knob")
        XCTAssertTrue(value(of: volume).contains("dB"))

        volume.tap()
        expectation(for: NSPredicate(format: "value == 'Muted'"), evaluatedWith: volume)
        waitForExpectations(timeout: 5)

        volume.tap()
        expectation(for: NSPredicate(format: "value CONTAINS 'dB'"), evaluatedWith: volume)
        waitForExpectations(timeout: 5)
    }

    #if os(iOS)
    func testSwipingChangesTheVolume() {
        launch(paired: true)
        let volume = knob("volumeKnob")
        waitFor(volume, "volume knob")
        let before = value(of: volume)

        volume.swipeUp()
        expectation(for: NSPredicate(format: "value != %@", before), evaluatedWith: volume)
        waitForExpectations(timeout: 5)
    }
    #endif

    func testChoosingADeviceInTheSearchConnectsToIt() {
        launch(paired: false)
        let device = app.descendants(matching: .any).matching(identifier: "foundDevice").firstMatch
        waitFor(device, "the simulated amplifier in the device list")
        screenshot("Search")

        device.tap()
        waitFor(knob("volumeKnob"), "volume knob")
    }

    func testSettingsOpenFromTheControls() {
        launch(paired: true)
        waitFor(knob("volumeKnob"), "volume knob")
        app.buttons["Settings"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Firmware: 2.1"].waitForExistence(timeout: 5)
                      || app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2.1'")).firstMatch.exists)
        screenshot("Settings")
    }
}
