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
        // Every option comes with a value ("-key value"): a stray argument would be treated as a file to open on the Mac,
        // and then the app opens no window
        app.launchArguments += ["-simulated-amplifier", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                                    // Do not restore windows of an earlier run (the test runner kills the app)
                                    "-ApplePersistenceIgnoreState", "YES"]
    }

    private func launch(paired: Bool) {
        if paired { app.launchArguments += ["-simulated-paired", "YES"] }
        app.launch()
        #if os(macOS)
        app.activate()
        _ = app.windows.firstMatch.waitForExistence(timeout: 10)
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

    /// On the Mac, the test runner cannot click in the app: after the first click the app stops answering
    /// the accessibility requests, although it works when used by hand. These tests run on the iPhone only.
    private func skipOnMac() throws {
        #if os(macOS)
        throw XCTSkip("Clicking in the app does not work in the macOS UI test environment; covered on iOS")
        #endif
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

    func testTappingTheVolumeKnobMutesAndUnmutes() throws {
        try skipOnMac()
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
    func testTurningTheKnobChangesTheVolume() {
        launch(paired: true)
        let volume = knob("volumeKnob")
        waitFor(volume, "volume knob")
        let before = value(of: volume)

        // A vertical drag on the right half of the knob turns it, because the angle to the center changes.
        // (A drag through the center would not turn it.)
        let start = volume.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.25))
        let end = volume.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.75))
        start.press(forDuration: 0.05, thenDragTo: end)
        expectation(for: NSPredicate(format: "value != %@", before), evaluatedWith: volume)
        waitForExpectations(timeout: 5)
    }
    #endif

    func testChoosingADeviceInTheSearchConnectsToIt() throws {
        try skipOnMac()
        launch(paired: false)
        let device = app.descendants(matching: .any).matching(identifier: "foundDevice").firstMatch
        waitFor(device, "the simulated amplifier in the device list")
        screenshot("Search")

        device.tap()
        waitFor(knob("volumeKnob"), "volume knob")
    }

    func testSettingsOpenFromTheControls() throws {
        try skipOnMac()
        launch(paired: true)
        waitFor(knob("volumeKnob"), "volume knob")
        app.buttons["Settings"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Firmware: 2.1"].waitForExistence(timeout: 5)
                      || app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2.1'")).firstMatch.exists)
        screenshot("Settings")
    }
}
