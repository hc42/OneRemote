import Foundation
import Combine

/// Waiting times of the connection handling. Tests use shorter ones.
struct AmpTiming {
    /// Give up a connection attempt after this long
    var connectTimeout = 15.0
    /// Pause before the automatic retry after a failed attempt
    var retryDelay = 4.0

    static let standard = AmpTiming()
}

final class AmpController: NSObject, ObservableObject {
    struct Found: Identifiable, Hashable {
        let id: UUID
        let name: String
    }

    @Published var status = String(localized: "Starting Bluetooth …")
    @Published var scanning = false
    @Published var found: [Found] = []
    @Published var connected = false
    @Published var deviceName = ""
    /// Connection setup in progress (shown in the connection view)
    @Published var connecting = false
    /// Show the device search menu instead of connection/controls
    @Published var showScan = true
    /// Last chosen device, persisted between app launches
    @Published private(set) var savedDevice: SavedDevice?

    struct SavedDevice: Equatable {
        let id: UUID
        let name: String
    }

    private enum Keys {
        static let id = "lastDeviceID"
        static let name = "lastDeviceName"
    }

    @Published var volume = 0
    @Published var muted = false
    @Published var input: AmpInput?
    @Published var hasDAC = false
    @Published var headphones = false
    @Published var avDirect = false
    /// true once the amplifier has reported the AV Direct state
    @Published var avDirectKnown = false
    @Published var serial = ""
    @Published var firmware = ""
    @Published var balance = 0
    /// Safety limit for the volume, persisted (default 60 of 90)
    @Published var maxVolume: Int = AmpBLE.defaultMaxVolume {
        didSet { defaults.set(maxVolume, forKey: "maxVolume") }
    }
    @Published var log: [String] = []

    private let transport: BLETransport
    private let defaults: UserDefaults
    private let timing: AmpTiming
    private var peripherals: [UUID: BLEPeripheralLink] = [:]
    private var peripheral: BLEPeripheralLink?
    /// The data channel is set up (notifications on), commands can be sent
    private var dataReady = false
    private var volumeWork: DispatchWorkItem?
    private var balanceWork: DispatchWorkItem?
    private var volumeFetchWork: DispatchWorkItem?
    /// Live sending of the volume: at most every 0.1 s, always the latest value
    private let volumeSendInterval = 0.1
    private var pendingVolume: Int?
    private var lastVolumeSend = Date.distantPast
    /// Live sending of the balance, same principle as the volume
    private let balanceSendInterval = 0.1
    private var pendingBalance: Int?
    private var lastBalanceSend = Date.distantPast
    private var balanceFetchWork: DispatchWorkItem?
    /// Input knob: the display jumps immediately, sending only happens after a short pause
    private var inputWork: DispatchWorkItem?
    private var pendingInput: AmpInput?
    private var lastInputSend = Date.distantPast
    /// Start time of the connection attempt, only used for the timing in the log
    private var connectStarted = Date()
    /// Writes without response that are waiting for free send capacity
    private var writeQueue: [Data] = []
    private var connectTimeout: DispatchWorkItem?
    /// While scanning: connect as soon as this device shows up (in case iOS no longer knows the UUID)
    private var autoTarget: UUID?
    /// Message that should stay visible after an abort
    private var pendingMessage: String?
    /// Newly chosen device, only saved after the first successful connection
    private var candidate: SavedDevice?
    /// Target for connection attempts: the newly chosen device first, otherwise the saved one
    private var target: SavedDevice? { candidate ?? savedDevice }
    /// Automatic retry after a failed connection attempt
    private var retryWork: DispatchWorkItem?
    private var attempt = 0

    init(transport: BLETransport = CoreBluetoothTransport(),
         defaults: UserDefaults = .standard,
         timing: AmpTiming = .standard) {
        self.transport = transport
        self.defaults = defaults
        self.timing = timing
        super.init()
        let saved = defaults.integer(forKey: "maxVolume")
        if saved != 0 { maxVolume = max(10, min(saved, AmpBLE.maxHardwareVolume)) }
        loadSavedDevice()
        transport.delegate = self
    }

    private func loadSavedDevice() {
        let d = defaults
        if let s = d.string(forKey: Keys.id), let id = UUID(uuidString: s) {
            let saved = SavedDevice(id: id, name: d.string(forKey: Keys.name) ?? "ONE")
            savedDevice = saved
            deviceName = saved.name
            showScan = false
            connecting = true // will connect after Bluetooth has started
        } else {
            showScan = true
        }
    }

    private func save(_ device: SavedDevice) {
        savedDevice = device
        defaults.set(device.id.uuidString, forKey: Keys.id)
        defaults.set(device.name, forKey: Keys.name)
    }

    // MARK: Actions

    func startScan() {
        guard transport.state == .poweredOn else { return }
        found.removeAll()
        peripherals.removeAll()
        scanning = true
        status = String(localized: "Searching for devices")
        transport.scan()
    }

    func stopScan() {
        transport.stopScan()
        scanning = false
    }

    /// Connect the device chosen in the search and remember it as the default
    func connect(_ id: UUID) {
        guard let p = peripherals[id] else { return }
        stopScan()
        let name = found.first(where: { $0.id == id })?.name ?? (p.name ?? "ONE")
        candidate = SavedDevice(id: id, name: name)
        showScan = false
        beginConnect(p, name: name)
    }

    /// Connect to the target device: the newly chosen one first, otherwise the saved one
    func connectToTarget() {
        guard let saved = target, transport.state == .poweredOn else { return }
        guard !connected else { return }
        abortConnect() // cleanly end any attempt in progress
        retryWork?.cancel()
        // Alternate between connecting directly with the known UUID and scanning. Some amplifiers show up
        // with a new address after being switched off; then only scanning helps (like the manual selection).
        attempt += 1
        let useScan = attempt % 2 == 0
        if !useScan, let p = transport.retrievePeripheral(id: saved.id) {
            peripherals[saved.id] = p
            beginConnect(p, name: saved.name)
            // Scan in parallel: if the amplifier shows up under a different identifier, the scan wins
            watchForTarget(saved)
        } else {
            // iOS does not know the UUID (any more): scan and connect when found
            deviceName = saved.name
            autoTarget = saved.id
            connecting = true
            status = String(localized: "Searching for \(saved.name) …")
            transport.scan()
            armTimeout()
        }
    }

    func retry() {
        connectToTarget()
    }

    /// Switch to the device search. Ends a running or existing connection.
    func openScan() {
        abortConnect()
        connected = false
        avDirectKnown = false
        showScan = true
        startScan()
    }

    /// Back from the device search to the saved device
    func closeScan() {
        guard savedDevice != nil else { return }
        candidate = nil // discard the unconfirmed selection
        stopScan()
        showScan = false
        connectToTarget()
    }

    private func beginConnect(_ p: BLEPeripheralLink, name: String) {
        connectStarted = Date()
        pendingMessage = nil
        peripheral = p
        deviceName = name
        connecting = true
        status = String(localized: "Connecting to \(name) …")
        transport.connect(p)
        armTimeout()
    }

    /// After an unexpected loss: keep the connection request open. iOS connects by itself
    /// as soon as the amplifier is reachable again. Deliberately without a timeout.
    private func reconnect(_ p: BLEPeripheralLink) {
        connectStarted = Date()
        peripheral = p
        connecting = true
        status = String(localized: "Connection lost. Waiting for \(deviceName) …")
        transport.connect(p)
        // With a time limit: if the amplifier is not found, failConnect tries again (alternating with a scan)
        armTimeout()
        if let saved = target { watchForTarget(saved) }
    }

    /// Scan in addition to the open connection request: as soon as the target device shows up (by identifier or name),
    /// connect using that result
    private func watchForTarget(_ saved: SavedDevice) {
        guard transport.state == .poweredOn, !scanning else { return }
        autoTarget = saved.id
        transport.scan()
    }

    /// Retry in a few seconds after a failure, as long as a saved device exists
    /// and the user is not in the device search
    private func scheduleRetry() {
        retryWork?.cancel()
        guard savedDevice != nil, candidate == nil, !showScan else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, !self.connected, !self.connecting, !self.showScan else { return }
            self.connectToTarget()
        }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.retryDelay, execute: work)
    }

    /// Bluetooth unusable: reset the state
    private func markOffline() {
        connecting = false
        connected = false
        avDirectKnown = false
        connectTimeout?.cancel()
    }

    private func armTimeout() {
        connectTimeout?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.connecting, !self.connected else { return }
            self.failConnect(String(localized: "Could not connect to \(self.deviceName). Is the amplifier on and in range?"))
        }
        connectTimeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.connectTimeout, execute: work)
    }

    /// Abort a connection attempt with a message
    private func failConnect(_ message: String) {
        pendingMessage = message
        status = message
        abortConnect()
        scheduleRetry()
    }

    /// Ends timer, scan and (half-)open connection
    private func abortConnect() {
        connectTimeout?.cancel()
        connectTimeout = nil
        autoTarget = nil
        connecting = false
        if !scanning { transport.stopScan() }
        if let p = peripheral { transport.cancelConnection(p) }
    }

    /// With AV Direct on the AV input the volume is fixed on the amplifier
    var volumeLocked: Bool { avDirect && input == .av }

    /// AV Direct is only offered from firmware 2.0
    var avDirectSupported: Bool { (Double(firmware) ?? 0) >= 2.0 }

    func setVolume(_ value: Int) {
        guard !volumeLocked else { return }
        let v = max(0, min(value, min(maxVolume, AmpBLE.maxHardwareVolume)))
        // Send nothing at the limits (silent, maximum), not even when the button is held
        guard v != volume || pendingVolume != nil else { return }
        volume = v
        pendingVolume = v
        // Live: send immediately if the last send was long enough ago, otherwise send the
        // latest value at the next possible moment. The last value is always sent.
        let elapsed = Date().timeIntervalSince(lastVolumeSend)
        if elapsed >= volumeSendInterval {
            flushVolume()
        } else if volumeWork == nil {
            let work = DispatchWorkItem { [weak self] in self?.flushVolume() }
            volumeWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + (volumeSendInterval - elapsed), execute: work)
        }
    }

    private func flushVolume() {
        volumeWork?.cancel()
        volumeWork = nil
        guard let v = pendingVolume else { return }
        pendingVolume = nil
        lastVolumeSend = Date()
        send(AmpBLE.valueBody(AmpBLE.Cmd.volume, value: v))
        // After the last send, fetch the real value from the amplifier
        requestVolume()
    }

    /// While we are sending volume ourselves, delayed responses from the amplifier
    /// would make the control jump back. Such responses are ignored.
    private var volumeEchoGuard: Bool {
        pendingVolume != nil || Date().timeIntervalSince(lastVolumeSend) < 0.25
    }

    func toggleMute() {
        let new = !muted
        muted = new
        send([AmpBLE.Cmd.mute, UInt8(ascii: "1"), new ? UInt8(ascii: "1") : UInt8(ascii: "0")])
        requestVolume()
    }

    /// Fetch the volume again after mute and headphone changes.
    /// Several requests in quick succession are combined into one.
    private func requestVolume() {
        volumeFetchWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.send([AmpBLE.Cmd.fetch, UInt8(ascii: "1"), AmpBLE.Cmd.volume])
        }
        volumeFetchWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    func select(_ input: AmpInput) {
        // A pending step must not overwrite the direct selection
        inputWork?.cancel()
        pendingInput = nil
        lastInputSend = Date()
        self.input = input
        send([AmpBLE.Cmd.input, UInt8(ascii: "1"), input.rawValue])
    }

    /// Advance the input by `delta` positions, endless (after the last one comes the first again).
    /// The display jumps immediately. Sending only happens once there has been no turning for 0.35 s,
    /// so the amplifier relays do not switch at every intermediate position.
    func stepInput(_ delta: Int) {
        let all = AmpInput.allCases
        let current = pendingInput ?? input ?? .bluetooth
        guard let index = all.firstIndex(of: current) else { return }
        let n = all.count
        let next = all[((index + delta) % n + n) % n]
        input = next
        pendingInput = next
        inputWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, let target = self.pendingInput else { return }
            self.pendingInput = nil
            self.lastInputSend = Date()
            self.send([AmpBLE.Cmd.input, UInt8(ascii: "1"), target.rawValue])
        }
        inputWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    func setBalance(_ value: Int) {
        guard !headphones else { return } // balance is disabled while headphones are connected
        let v = max(0, min(value, 20))
        balance = v
        pendingBalance = v
        let elapsed = Date().timeIntervalSince(lastBalanceSend)
        if elapsed >= balanceSendInterval {
            flushBalance()
        } else if balanceWork == nil {
            let work = DispatchWorkItem { [weak self] in self?.flushBalance() }
            balanceWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + (balanceSendInterval - elapsed), execute: work)
        }
    }

    private func flushBalance() {
        balanceWork?.cancel()
        balanceWork = nil
        guard let v = pendingBalance else { return }
        pendingBalance = nil
        lastBalanceSend = Date()
        send(AmpBLE.valueBody(AmpBLE.Cmd.balance, value: v))
        // After the last send, fetch the real value from the amplifier
        balanceFetchWork?.cancel()
        let fetch = DispatchWorkItem { [weak self] in
            self?.send([AmpBLE.Cmd.fetch, UInt8(ascii: "1"), AmpBLE.Cmd.balance])
        }
        balanceFetchWork = fetch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: fetch)
    }

    /// Ignore responses from the amplifier while sending ourselves (no jumping back)
    private var balanceEchoGuard: Bool {
        pendingBalance != nil || Date().timeIntervalSince(lastBalanceSend) < 0.25
    }

    /// Display: 10 = center, 0 = fully left (100), 20 = fully right (100)
    var balanceText: String {
        let diff = (balance - 10) * 10
        if diff == 0 { return String(localized: "Center") }
        return diff < 0 ? String(localized: "Left \(-diff)") : String(localized: "Right \(diff)")
    }

    func brightness(up: Bool) {
        send([AmpBLE.Cmd.brightness, UInt8(ascii: "1"), up ? UInt8(ascii: "+") : UInt8(ascii: "-")])
    }

    /// CAUTION: The command `@+A11%` is a toggle. Enabling and disabling send the same thing.
    /// So only send it if the current state is known and the firmware fits.
    /// The confirmations happen in the UI (AVDirectView).
    func toggleAVDirect() {
        guard connected, avDirectKnown, avDirectSupported else { return }
        send([AmpBLE.Cmd.avDirect, UInt8(ascii: "1"), UInt8(ascii: "1")])
        // Fetch the state again as a check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.send([AmpBLE.Cmd.fetch, UInt8(ascii: "1"), AmpBLE.Cmd.avDirect])
        }
    }

    func refresh() {
        // No artificial pauses: CoreBluetooth queues writes with response by itself, one after another
        for cmd in AmpBLE.initialFetch {
            send([AmpBLE.Cmd.fetch, UInt8(ascii: "1"), cmd])
        }
    }

    // MARK: Sending and receiving

    private func send(_ body: [UInt8]) {
        guard let p = peripheral, dataReady else { return }
        let data = AmpBLE.frame(body)
        appendLog("→ " + hex(data))
        if p.writesWithResponse {
            p.write(data, withResponse: true)
        } else if p.canSendWriteWithoutResponse && writeQueue.isEmpty {
            p.write(data, withResponse: false)
        } else {
            writeQueue.append(data) // is sent in bleReadyToWriteWithoutResponse
        }
    }

    private func handle(_ d: [UInt8]) {
        appendLog("← " + hex(Data(d)))
        guard let event = AmpParser.parse(d) else { return }

        switch event {
        case .avDirect(let on):
            avDirect = on
            avDirectKnown = true
        case .hasDAC(let yes): hasDAC = yes
        case .headphones(let yes):
            headphones = yes
            requestVolume()
        case .mute(let on):
            muted = on
            requestVolume()
        case .input(let new):
            // Do not overwrite our own choice that has not been sent yet or has just been sent
            if pendingInput == nil, Date().timeIntervalSince(lastInputSend) > 0.6 {
                input = new
            }
        case .volume(let v):
            if !volumeEchoGuard { volume = v }
        case .balance(let v):
            if !balanceEchoGuard { balance = v }
        case .firmware(let version): firmware = version
        case .serial(let text): serial = text
        }
    }

    private func appendLog(_ s: String) {
        log.append(s)
        if log.count > 200 { log.removeFirst(log.count - 200) }
    }

    private func hex(_ data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

// MARK: - Bluetooth events

extension AmpController: BLETransportDelegate {
    func bleStateChanged(_ state: BLEState) {
        switch state {
        case .poweredOn:
            status = String(localized: "Bluetooth ready")
            if showScan {
                startScan()
            } else {
                connectToTarget()
            }
        case .poweredOff:
            markOffline()
            status = String(localized: "Bluetooth is turned off")
        case .unauthorized:
            markOffline()
            status = String(localized: "Bluetooth access denied (check system settings)")
        case .unavailable:
            markOffline()
            status = String(localized: "Bluetooth unavailable")
        }
    }

    func bleDidDiscover(_ link: BLEPeripheralLink, advertisedName advName: String?) {
        // Also recognize by name: after being switched off the amplifier can show up with a new address
        if let targetID = autoTarget,
           link.id == targetID || (advName != nil && advName == target?.name) {
            autoTarget = nil
            transport.stopScan()
            peripherals[link.id] = link
            // End a still-open request to another (stale) peripheral
            if let old = peripheral, old.id != link.id {
                transport.cancelConnection(old)
            }
            beginConnect(link, name: target?.name ?? link.name ?? "ONE")
            return
        }
        let name = advName ?? ""
        guard name.hasPrefix(AmpBLE.namePrefix) else { return }
        peripherals[link.id] = link
        let item = Found(id: link.id, name: name)
        if let i = found.firstIndex(where: { $0.id == item.id }) {
            found[i] = item
        } else {
            found.append(item)
        }
    }

    func bleDidConnect(_ link: BLEPeripheralLink) {
        status = String(localized: "Connected, discovering services …")
        link.discoverAndSubscribe()
    }

    func bleDidFailToConnect(_ link: BLEPeripheralLink, error: Error?) {
        failConnect(String(localized: "Connection failed: \(error?.localizedDescription ?? String(localized: "unknown"))"))
    }

    func bleDidDisconnect(_ link: BLEPeripheralLink, error: Error?) {
        let wasConnected = connected
        connected = false
        connecting = false
        connectTimeout?.cancel()
        avDirectKnown = false
        dataReady = false
        writeQueue.removeAll()
        self.peripheral = nil
        if let message = pendingMessage {
            status = message
            pendingMessage = nil
        } else if wasConnected && !showScan {
            // Unexpected loss (amplifier off, out of range): reconnect automatically
            reconnect(link)
        } else {
            status = error.map { String(localized: "Disconnected: \($0.localizedDescription)") } ?? String(localized: "Disconnected")
        }
    }

    func bleSubscriptionFailed(_ link: BLEPeripheralLink, failure: BLELinkFailure) {
        switch failure {
        case .serviceNotFound:
            failConnect(String(localized: "Control service not found"))
        case .characteristicNotFound:
            failConnect(String(localized: "Data characteristic not found"))
        case .notificationsFailed(let error):
            // Typical on first use: confirm the pairing dialog, then connect again
            failConnect(String(localized: "Enabling notifications failed: \(error.localizedDescription)"))
        }
    }

    func bleDidSubscribe(_ link: BLEPeripheralLink) {
        dataReady = true
        connected = true
        connecting = false
        attempt = 0
        retryWork?.cancel()
        autoTarget = nil
        if !scanning { transport.stopScan() }
        connectTimeout?.cancel()
        status = String(localized: "Connected")
        appendLog(String(format: "Ready after %.1f s", Date().timeIntervalSince(connectStarted)))
        // Only now, after the first successful connection, the device is saved as the default
        if let device = candidate {
            save(device)
            candidate = nil
        } else if let saved = savedDevice, saved.id != link.id {
            // The amplifier reported itself with a new identifier (name matches): remember the new identifier
            save(SavedDevice(id: link.id, name: saved.name))
        }
        refresh()
    }

    func bleDidReceive(_ data: Data, from link: BLEPeripheralLink) {
        handle([UInt8](data))
    }

    func bleReadyToWriteWithoutResponse(_ link: BLEPeripheralLink) {
        guard dataReady else { return }
        while !writeQueue.isEmpty, link.canSendWriteWithoutResponse {
            link.write(writeQueue.removeFirst(), withResponse: false)
        }
    }

    func bleWriteFailed(_ link: BLEPeripheralLink, error: Error) {
        appendLog("Write error: \(error.localizedDescription)")
    }
}
