import Foundation
import CoreBluetooth

/// The real Bluetooth stack: `BLETransport` on top of `CBCentralManager`.
final class CoreBluetoothTransport: NSObject, BLETransport {
    weak var delegate: BLETransportDelegate?
    private var central: CBCentralManager!
    /// Keeps the links alive: `CBPeripheral` only holds its delegate weakly
    private var links: [UUID: CoreBluetoothLink] = [:]

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    var state: BLEState { Self.map(central.state) }

    private static func map(_ state: CBManagerState) -> BLEState {
        switch state {
        case .poweredOn: return .poweredOn
        case .poweredOff: return .poweredOff
        case .unauthorized: return .unauthorized
        default: return .unavailable
        }
    }

    func scan() {
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopScan() {
        central.stopScan()
    }

    func retrievePeripheral(id: UUID) -> BLEPeripheralLink? {
        guard let p = central.retrievePeripherals(withIdentifiers: [id]).first else { return nil }
        return link(for: p)
    }

    func connect(_ link: BLEPeripheralLink) {
        guard let l = link as? CoreBluetoothLink else { return }
        central.connect(l.peripheral, options: nil)
    }

    func cancelConnection(_ link: BLEPeripheralLink) {
        guard let l = link as? CoreBluetoothLink else { return }
        central.cancelPeripheralConnection(l.peripheral)
    }

    fileprivate func link(for peripheral: CBPeripheral) -> CoreBluetoothLink {
        if let existing = links[peripheral.identifier], existing.peripheral === peripheral {
            return existing
        }
        let link = CoreBluetoothLink(peripheral: peripheral, transport: self)
        links[peripheral.identifier] = link
        return link
    }
}

extension CoreBluetoothTransport: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.bleStateChanged(Self.map(central.state))
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name
        delegate?.bleDidDiscover(link(for: peripheral), advertisedName: name)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.bleDidConnect(link(for: peripheral))
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.bleDidFailToConnect(link(for: peripheral), error: error)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let l = link(for: peripheral)
        l.reset()
        delegate?.bleDidDisconnect(l, error: error)
    }
}

/// One `CBPeripheral` with the discovery of the control service and the data characteristic
final class CoreBluetoothLink: NSObject, BLEPeripheralLink, CBPeripheralDelegate {
    let peripheral: CBPeripheral
    private weak var transport: CoreBluetoothTransport?
    private var dataChar: CBCharacteristic?

    init(peripheral: CBPeripheral, transport: CoreBluetoothTransport) {
        self.peripheral = peripheral
        self.transport = transport
        super.init()
        peripheral.delegate = self
    }

    var id: UUID { peripheral.identifier }
    var name: String? { peripheral.name }
    var writesWithResponse: Bool { dataChar?.properties.contains(.write) ?? false }
    var canSendWriteWithoutResponse: Bool { peripheral.canSendWriteWithoutResponse }

    /// After a disconnect the old characteristic is no longer valid
    func reset() {
        dataChar = nil
    }

    func discoverAndSubscribe() {
        peripheral.discoverServices([AmpBLE.service])
    }

    func write(_ data: Data, withResponse: Bool) {
        guard let c = dataChar else { return }
        peripheral.writeValue(data, for: c, type: withResponse ? .withResponse : .withoutResponse)
    }

    private var delegate: BLETransportDelegate? { transport?.delegate }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == AmpBLE.service }) else {
            delegate?.bleSubscriptionFailed(self, failure: .serviceNotFound)
            return
        }
        peripheral.discoverCharacteristics([AmpBLE.dataCharacteristic], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let c = service.characteristics?.first(where: { $0.uuid == AmpBLE.dataCharacteristic }) else {
            delegate?.bleSubscriptionFailed(self, failure: .characteristicNotFound)
            return
        }
        dataChar = c
        peripheral.setNotifyValue(true, for: c)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            delegate?.bleSubscriptionFailed(self, failure: .notificationsFailed(error))
            return
        }
        guard characteristic.isNotifying else { return }
        delegate?.bleDidSubscribe(self)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == AmpBLE.dataCharacteristic, let data = characteristic.value else { return }
        delegate?.bleDidReceive(data, from: self)
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        delegate?.bleReadyToWriteWithoutResponse(self)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error { delegate?.bleWriteFailed(self, error: error) }
    }
}
