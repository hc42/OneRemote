import XCTest

/// Tests of the connection handling and the sending rules, against a simulated amplifier.
final class AmpControllerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite = ""

    override func setUp() {
        super.setUp()
        suite = "AmpControllerTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    // MARK: Helpers

    /// The check for a dead link (probeTimeout) is practically off, so it does not interfere with other tests
    private let fast = AmpTiming(connectTimeout: 0.3, retryDelay: 0.1, probeTimeout: 30)
    /// For the tests of the check for a dead link
    private let probing = AmpTiming(connectTimeout: 5, retryDelay: 0.1, probeTimeout: 0.1, restartDelay: 0.05)

    private func saveDevice(id: UUID, name: String = "ONE 1234") {
        defaults.set(id.uuidString, forKey: "lastDeviceID")
        defaults.set(name, forKey: "lastDeviceName")
    }

    private func makeController(_ transport: FakeTransport, timing: AmpTiming? = nil) -> AmpController {
        AmpController(transport: transport, defaults: defaults, timing: timing ?? fast)
    }

    /// Any frame from the amplifier (the real one answers every request)
    private func answerFrame() -> Data {
        AmpBLE.frame(AmpBLE.valueBody(AmpBLE.Cmd.volume, value: 40))
    }

    /// Runs the main run loop until the condition holds (or fails the test after the timeout)
    private func wait(_ message: String, timeout: TimeInterval = 3,
                      file: StaticString = #filePath, line: UInt = #line,
                      until condition: () -> Bool) {
        let end = Date().addingTimeInterval(timeout)
        while !condition() && Date() < end {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertTrue(condition(), "Timed out waiting for: \(message)", file: file, line: line)
    }

    private func pause(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    private func fetchFrame(_ cmd: UInt8) -> Data {
        AmpBLE.frame([AmpBLE.Cmd.fetch, UInt8(ascii: "1"), cmd])
    }

    /// A controller that is connected to a known amplifier
    private func connectedController() -> (AmpController, FakeTransport, FakeLink) {
        let amp = FakeLink()
        let transport = FakeTransport(amp: amp)
        transport.knownLinks[amp.id] = amp
        saveDevice(id: amp.id)
        let controller = makeController(transport)
        transport.powerOn()
        wait("connected") { controller.connected }
        return (controller, transport, amp)
    }

    // MARK: Connecting

    func testConnectsToSavedDeviceAndFetchesState() {
        let (controller, _, amp) = connectedController()
        XCTAssertFalse(controller.showScan)
        XCTAssertEqual(amp.writes, AmpBLE.initialFetch.map(fetchFrame))
    }

    func testWithoutSavedDeviceItShowsTheSearch() {
        let transport = FakeTransport()
        let controller = makeController(transport)
        transport.powerOn()
        XCTAssertTrue(controller.showScan)
        XCTAssertFalse(controller.connected)
    }

    func testChosenDeviceIsOnlySavedAfterSuccessfulConnection() {
        let amp = FakeLink(name: "ONE 5678")
        let transport = FakeTransport(amp: amp)
        let controller = makeController(transport)
        transport.powerOn()
        wait("device found") { !controller.found.isEmpty }
        XCTAssertNil(defaults.string(forKey: "lastDeviceID"))

        controller.connect(amp.id)
        wait("connected") { controller.connected }
        XCTAssertEqual(defaults.string(forKey: "lastDeviceID"), amp.id.uuidString)
        XCTAssertEqual(defaults.string(forKey: "lastDeviceName"), "ONE 5678")
    }

    func testReconnectsByNameWhenTheIdentifierChanged() {
        let oldID = UUID()
        saveDevice(id: oldID)
        let newAmp = FakeLink(name: "ONE 1234")
        let transport = FakeTransport(amp: newAmp)   // the system no longer knows oldID
        let controller = makeController(transport)
        transport.powerOn()

        wait("connected") { controller.connected }
        XCTAssertEqual(defaults.string(forKey: "lastDeviceID"), newAmp.id.uuidString,
                       "The new identifier must be remembered")
    }

    func testDoesNotConnectToAnotherAmplifier() {
        saveDevice(id: UUID(), name: "ONE 1234")
        let other = FakeLink(name: "ONE 9999")
        let transport = FakeTransport(amp: other)
        let controller = makeController(transport)
        transport.powerOn()
        pause(0.2)
        XCTAssertFalse(controller.connected)
        XCTAssertEqual(transport.connectCount, 0)
    }

    // MARK: Connection loss and retry

    func testReconnectsAfterTheAmplifierWasSwitchedOffAndOn() {
        let (controller, transport, amp) = connectedController()
        let connectsBefore = transport.connectCount

        transport.disappear()
        XCTAssertFalse(controller.connected)
        XCTAssertTrue(controller.connecting, "Must keep waiting for the amplifier")
        XCTAssertEqual(transport.connectCount, connectsBefore + 1, "A new request must be open")

        transport.appear()
        wait("connected again") { controller.connected }
        XCTAssertEqual(amp.writes(command: AmpBLE.Cmd.fetch).count, AmpBLE.initialFetch.count * 2,
                       "The state is fetched again after reconnecting")
    }

    func testReconnectsToTheNewIdentifierAfterAPowerCycle() {
        let (controller, transport, _) = connectedController()
        transport.disappear()
        let newAmp = FakeLink(name: "ONE 1234")
        transport.reappear(as: newAmp)

        wait("connected to the new identifier") { controller.connected }
        XCTAssertEqual(defaults.string(forKey: "lastDeviceID"), newAmp.id.uuidString)
    }

    func testKeepsTryingWhileTheAmplifierIsOff() {
        let amp = FakeLink()
        let transport = FakeTransport(amp: amp, reachable: false)
        transport.knownLinks[amp.id] = amp
        saveDevice(id: amp.id)
        let controller = makeController(transport)
        transport.powerOn()

        // Timeout (0.3 s), then retry after 0.1 s
        wait("a second attempt") { transport.scanCount >= 2 }
        XCTAssertFalse(controller.connected)

        transport.appear()
        wait("connected") { controller.connected }
    }

    func testBluetoothTurnedOffResetsTheState() {
        let (controller, transport, _) = connectedController()
        transport.state = .poweredOff
        controller.bleStateChanged(.poweredOff)
        XCTAssertFalse(controller.connected)
        XCTAssertFalse(controller.connecting)
    }

    // MARK: Sending

    func testTheLastVolumeIsAlwaysSentAndSendingIsLimited() {
        let (controller, _, amp) = connectedController()
        let before = amp.writes(command: AmpBLE.Cmd.volume).count

        for v in 1...20 { controller.setVolume(v) }
        pause(0.5)

        let sent = Array(amp.writes(command: AmpBLE.Cmd.volume).dropFirst(before))
        XCTAssertEqual(sent.last, AmpBLE.frame(AmpBLE.valueBody(AmpBLE.Cmd.volume, value: 20)))
        XCTAssertLessThan(sent.count, 20, "Not every intermediate value may be sent")
        XCTAssertEqual(controller.volume, 20)
    }

    func testVolumeIsLimitedToTheSafetyLimit() {
        let (controller, _, amp) = connectedController()
        controller.maxVolume = 40
        controller.setVolume(80)
        pause(0.2)

        XCTAssertEqual(controller.volume, 40)
        XCTAssertEqual(amp.writes(command: AmpBLE.Cmd.volume).last,
                       AmpBLE.frame(AmpBLE.valueBody(AmpBLE.Cmd.volume, value: 40)))
    }

    func testSafetyLimitIsPersistedAndRestored() {
        let (controller, _, _) = connectedController()
        controller.maxVolume = 45
        let again = makeController(FakeTransport())
        XCTAssertEqual(again.maxVolume, 45)
    }

    func testVolumeIsFixedWithAVDirectOnTheAVInput() {
        let (controller, transport, amp) = connectedController()
        transport.deliver(AmpBLE.frame([AmpBLE.Cmd.avDirect, UInt8(ascii: "1"), UInt8(ascii: "1")]))
        transport.deliver(AmpBLE.frame([AmpBLE.Cmd.input, UInt8(ascii: "1"), AmpInput.av.rawValue]))
        XCTAssertTrue(controller.volumeLocked)
        let before = amp.writes(command: AmpBLE.Cmd.volume).count

        controller.setVolume(30)
        pause(0.2)
        XCTAssertEqual(amp.writes(command: AmpBLE.Cmd.volume).count, before)
    }

    func testAVDirectCanOnlyBeToggledWithKnownStateAndSupportedFirmware() {
        let (controller, transport, amp) = connectedController()
        let toggle = AmpBLE.frame([AmpBLE.Cmd.avDirect, UInt8(ascii: "1"), UInt8(ascii: "1")])

        controller.toggleAVDirect()   // state unknown
        XCTAssertFalse(amp.writes.contains(toggle))

        transport.deliver(AmpBLE.frame([AmpBLE.Cmd.avDirect, UInt8(ascii: "1"), UInt8(ascii: "0")]))
        controller.toggleAVDirect()   // firmware unknown
        XCTAssertFalse(amp.writes.contains(toggle))

        transport.deliver(AmpBLE.frame([AmpBLE.Cmd.version, UInt8(ascii: "2"), UInt8(ascii: "2"), UInt8(ascii: "1")]))
        controller.toggleAVDirect()
        XCTAssertTrue(amp.writes.contains(toggle))
    }

    func testAVDirectStateIsForgottenWhenTheConnectionIsLost() {
        let (controller, transport, _) = connectedController()
        transport.deliver(AmpBLE.frame([AmpBLE.Cmd.avDirect, UInt8(ascii: "1"), UInt8(ascii: "1")]))
        XCTAssertTrue(controller.avDirectKnown)
        transport.disappear()
        XCTAssertFalse(controller.avDirectKnown)
    }

    // MARK: Dead links (app was in the background for a long time)

    func testALinkThatDoesNotAnswerAfterComingToTheFrontIsDroppedAndReopened() {
        let amp = FakeLink()
        let transport = FakeTransport(amp: amp)
        transport.reportsCancelledLinks = true
        transport.knownLinks[amp.id] = amp
        saveDevice(id: amp.id)
        let controller = makeController(transport, timing: probing)
        transport.powerOn()
        wait("connected") { controller.connected }
        transport.deliver(answerFrame()) // the first answer arrives, the link is fine
        pause(0.3)
        XCTAssertEqual(transport.connectCount, 1)

        // Hours later: the system dropped the link without the app noticing, nothing answers any more
        controller.appBecameActive()
        wait("the dead link is dropped and a new connection is opened") { transport.connectCount >= 2 }
        XCTAssertGreaterThanOrEqual(transport.cancelCount, 1)
    }

    func testALinkThatAnswersStaysOpenWhenTheAppComesToTheFront() {
        let amp = FakeLink()
        let transport = FakeTransport(amp: amp)
        transport.reportsCancelledLinks = true
        transport.knownLinks[amp.id] = amp
        saveDevice(id: amp.id)
        let controller = makeController(transport, timing: probing)
        transport.powerOn()
        wait("connected") { controller.connected }
        transport.deliver(answerFrame())

        let writesBefore = amp.writes.count
        controller.appBecameActive()
        pause(0.03)
        transport.deliver(answerFrame())
        pause(0.5)
        XCTAssertTrue(controller.connected)
        XCTAssertEqual(transport.connectCount, 1)
        XCTAssertGreaterThan(amp.writes.count, writesBefore) // the values were requested again
    }

    func testAFreshLinkThatNeverAnswersIsReopened() {
        // The amplifier has just been switched on and its Bluetooth is up, but it does not answer yet
        let amp = FakeLink()
        let transport = FakeTransport(amp: amp)
        transport.reportsCancelledLinks = true
        transport.knownLinks[amp.id] = amp
        saveDevice(id: amp.id)
        let controller = makeController(transport, timing: probing)
        transport.powerOn()
        wait("connected") { controller.connected }
        wait("the silent link is dropped and a new one is opened") { transport.connectCount >= 2 }
        XCTAssertGreaterThanOrEqual(amp.writes.count, AmpBLE.initialFetch.count * 2) // asked again before giving up
    }

    func testNothingIsSentWhenNotConnected() {
        let amp = FakeLink()
        let transport = FakeTransport(amp: amp, reachable: false)
        let controller = makeController(transport)
        controller.toggleMute()
        controller.setVolume(10)
        pause(0.2)
        XCTAssertTrue(amp.writes.isEmpty)
    }
}
