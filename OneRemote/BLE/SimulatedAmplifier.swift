import Foundation

/// A simulated amplifier instead of Bluetooth. It serves two purposes:
/// - Demo mode (all builds): "Try the demo" in the device search, so that App Review and anyone
///   without the hardware can try the app. Nothing is sent over Bluetooth or the network.
/// - UI tests and store screenshots (debug builds): launch argument `-simulated-amplifier YES`
///   (plus `-simulated-paired YES` to start with the amplifier already chosen).
/// Write the options as `-key YES`: a lone argument would be treated as a file to open on the Mac.
/// It answers the same frames as the real amplifier (see docs/PROTOCOL.md).
final class SimulatedAmplifier: BLETransport {
    static let deviceID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    static let deviceName = "ONE HD 0001"

    weak var delegate: BLETransportDelegate? {
        didSet {
            // Like CoreBluetooth: the state is reported once the delegate is set
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.bleStateChanged(.poweredOn)
            }
        }
    }
    var state: BLEState { .poweredOn }

    private let link = Link()
    private var scanning = false
    private var connected = false

    // State of the simulated amplifier
    private var input = AmpInput.usbB
    private var volume = 40
    private var muted = false
    private var avDirect = false
    private var balance = 10

    init() {
        link.owner = self
    }

    /// Controller for the launch arguments of the UI tests
    static func makeController(arguments: [String]) -> AmpController {
        let suite = "OneRemote-Simulated"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        if arguments.contains("-simulated-paired") {
            defaults.set(deviceID.uuidString, forKey: "lastDeviceID")
            defaults.set(deviceName, forKey: "lastDeviceName")
        }
        return AmpController(transport: SimulatedAmplifier(), defaults: defaults)
    }

    /// Controller for the demo mode: starts already connected to the simulated amplifier.
    /// Uses its own settings, so the saved real device and the volume limit stay untouched.
    static func makeDemoController() -> AmpController {
        let suite = "OneRemote-Demo"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        defaults.set(deviceID.uuidString, forKey: "lastDeviceID")
        defaults.set(deviceName, forKey: "lastDeviceName")
        return AmpController(transport: SimulatedAmplifier(), defaults: defaults, isDemo: true)
    }

    // MARK: BLETransport

    func scan() {
        scanning = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.scanning else { return }
            self.delegate?.bleDidDiscover(self.link, advertisedName: Self.deviceName)
        }
    }

    func stopScan() { scanning = false }

    func retrievePeripheral(id: UUID) -> BLEPeripheralLink? {
        id == Self.deviceID ? link : nil
    }

    func connect(_ link: BLEPeripheralLink) {
        guard !connected else { return }
        connected = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.connected else { return }
            self.delegate?.bleDidConnect(self.link)
        }
    }

    func cancelConnection(_ link: BLEPeripheralLink) {
        connected = false
    }

    // MARK: Amplifier

    fileprivate func subscribed() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleDidSubscribe(self.link)
        }
    }

    fileprivate func receive(_ data: Data) {
        let d = [UInt8](data)
        guard d.count >= 5, d[0] == AmpBLE.start else { return }
        let cmd = d[2], arg = d[4]
        let on = arg != UInt8(ascii: "0")
        switch cmd {
        case AmpBLE.Cmd.fetch: answer(arg)
        case AmpBLE.Cmd.volume:
            if d.count >= 6, let v = Int(String(decoding: d[4...5], as: UTF8.self)) { volume = v }
        case AmpBLE.Cmd.mute: muted = on
        case AmpBLE.Cmd.input: if let i = AmpInput(rawValue: arg) { input = i }
        case AmpBLE.Cmd.avDirect: avDirect.toggle()
        case AmpBLE.Cmd.balance:
            if d.count >= 6, let v = Int(String(decoding: d[4...5], as: UTF8.self)) { balance = v }
        default: break
        }
    }

    private func answer(_ cmd: UInt8) {
        func flag(_ on: Bool) -> [UInt8] { [cmd, UInt8(ascii: "1"), UInt8(ascii: on ? "1" : "0")] }
        let body: [UInt8]
        switch cmd {
        case AmpBLE.Cmd.volume: body = AmpBLE.valueBody(cmd, value: volume)
        case AmpBLE.Cmd.balance: body = AmpBLE.valueBody(cmd, value: balance)
        case AmpBLE.Cmd.mute: body = flag(muted)
        case AmpBLE.Cmd.input: body = [cmd, UInt8(ascii: "1"), input.rawValue]
        case AmpBLE.Cmd.hasDAC: body = flag(true)
        case AmpBLE.Cmd.headphones: body = flag(false)
        case AmpBLE.Cmd.avDirect: body = flag(avDirect)
        case AmpBLE.Cmd.version: body = [cmd, UInt8(ascii: "2"), UInt8(ascii: "2"), UInt8(ascii: "1")]
        case AmpBLE.Cmd.serial:
            let serial = Array("SIM0001".utf8)
            body = [cmd, UInt8(ascii: "7")] + serial
        default: return
        }
        let frame = AmpBLE.frame(body)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleDidReceive(frame, from: self.link)
        }
    }

    private final class Link: BLEPeripheralLink {
        weak var owner: SimulatedAmplifier?
        var id: UUID { SimulatedAmplifier.deviceID }
        var name: String? { SimulatedAmplifier.deviceName }
        var writesWithResponse: Bool { true }
        var canSendWriteWithoutResponse: Bool { true }
        func discoverAndSubscribe() { owner?.subscribed() }
        func write(_ data: Data, withResponse: Bool) { owner?.receive(data) }
    }
}
