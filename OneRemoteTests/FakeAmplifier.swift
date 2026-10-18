import Foundation

/// A simulated amplifier for tests of `AmpController`: it plays the role of the Bluetooth stack.
/// Like the real thing, a connection request to a device that is not reachable stays open until the
/// device shows up. All events are delivered asynchronously on the main queue.

final class FakeLink: BLEPeripheralLink {
    let id: UUID
    var name: String?
    var writesWithResponse = true
    var canSendWriteWithoutResponse = true
    private(set) var writes: [Data] = []
    weak var transport: FakeTransport?

    init(id: UUID = UUID(), name: String? = "ONE 1234") {
        self.id = id
        self.name = name
    }

    func discoverAndSubscribe() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let t = self.transport else { return }
            t.delegate?.bleDidSubscribe(self)
        }
    }

    func write(_ data: Data, withResponse: Bool) {
        writes.append(data)
    }

    /// Command letters of everything written so far with the given letter at the command position
    func writes(command: UInt8) -> [Data] {
        writes.filter { $0.count > 2 && $0[2] == command }
    }
}

final class FakeTransport: BLETransport {
    weak var delegate: BLETransportDelegate?
    var state: BLEState = .poweredOn

    /// The amplifier as it currently presents itself (identifier and advertised name)
    var amp: FakeLink
    private(set) var reachable: Bool
    /// Devices that the system still knows by identifier
    var knownLinks: [UUID: FakeLink] = [:]

    private(set) var scanCount = 0
    private(set) var connectCount = 0
    private(set) var cancelCount = 0
    private var scanning = false
    private var pending: FakeLink?
    private var connected: FakeLink?

    init(amp: FakeLink = FakeLink(), reachable: Bool = true) {
        self.amp = amp
        self.reachable = reachable
        amp.transport = self
    }

    // MARK: BLETransport

    func scan() {
        scanCount += 1
        scanning = true
        if reachable { announce() }
    }

    func stopScan() {
        scanning = false
    }

    func retrievePeripheral(id: UUID) -> BLEPeripheralLink? {
        knownLinks[id]
    }

    func connect(_ link: BLEPeripheralLink) {
        connectCount += 1
        guard let l = link as? FakeLink else { return }
        // Like CoreBluetooth: a second request for a device that is connected or connecting changes nothing
        guard connected !== l else { return }
        pending = l
        if reachable && l === amp { complete(l) }
    }

    func cancelConnection(_ link: BLEPeripheralLink) {
        cancelCount += 1
        if pending === link { pending = nil }
    }

    // MARK: Test control

    /// Bluetooth turned on (the controller starts working after this)
    func powerOn() {
        delegate?.bleStateChanged(.poweredOn)
    }

    /// The amplifier is switched on or comes back into range
    func appear() {
        reachable = true
        if scanning { announce() }
        if let p = pending, p === amp { complete(p) }
    }

    /// The amplifier is switched off or out of range. A connected link is lost.
    func disappear() {
        reachable = false
        if let c = connected {
            connected = nil
            delegate?.bleDidDisconnect(c, error: nil)
        }
    }

    /// After a power cycle the amplifier can show up with a different identifier
    func reappear(as newAmp: FakeLink) {
        amp = newAmp
        newAmp.transport = self
        appear()
    }

    /// The amplifier sends a notification
    func deliver(_ frame: Data) {
        guard let c = connected else { return }
        delegate?.bleDidReceive(frame, from: c)
    }

    // MARK: Internals

    private func announce() {
        let link = amp
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.scanning else { return }
            self.delegate?.bleDidDiscover(link, advertisedName: link.name)
        }
    }

    private func complete(_ link: FakeLink) {
        pending = nil
        connected = link
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.connected === link else { return }
            self.delegate?.bleDidConnect(link)
        }
    }
}
