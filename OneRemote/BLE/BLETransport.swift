import Foundation

/// What `AmpController` needs from the Bluetooth stack. The real implementation wraps CoreBluetooth
/// (`CoreBluetoothTransport`); tests use a simulated amplifier. No CoreBluetooth types appear here.

enum BLEState: Equatable {
    case poweredOn
    case poweredOff
    case unauthorized
    /// Unknown, resetting or unsupported
    case unavailable
}

/// Why setting up the data channel of a connected device failed
enum BLELinkFailure {
    case serviceNotFound
    case characteristicNotFound
    /// Typical on first use: the pairing dialog has to be confirmed first
    case notificationsFailed(Error)
}

/// One Bluetooth device, as far as the controller is concerned
protocol BLEPeripheralLink: AnyObject {
    var id: UUID { get }
    var name: String? { get }
    /// Whether the data characteristic is written with response (otherwise without)
    var writesWithResponse: Bool { get }
    var canSendWriteWithoutResponse: Bool { get }
    /// Finds the control service and the data characteristic and enables notifications.
    /// The result arrives as `bleDidSubscribe` or `bleSubscriptionFailed`.
    func discoverAndSubscribe()
    func write(_ data: Data, withResponse: Bool)
}

protocol BLETransport: AnyObject {
    var delegate: BLETransportDelegate? { get set }
    var state: BLEState { get }
    /// Scans for all devices (the controller filters by name)
    func scan()
    func stopScan()
    /// The device with this identifier, if the system still knows it
    func retrievePeripheral(id: UUID) -> BLEPeripheralLink?
    func connect(_ link: BLEPeripheralLink)
    func cancelConnection(_ link: BLEPeripheralLink)
}

protocol BLETransportDelegate: AnyObject {
    func bleStateChanged(_ state: BLEState)
    /// `advertisedName`: the advertised local name, otherwise the device name
    func bleDidDiscover(_ link: BLEPeripheralLink, advertisedName: String?)
    func bleDidConnect(_ link: BLEPeripheralLink)
    func bleDidFailToConnect(_ link: BLEPeripheralLink, error: Error?)
    func bleDidDisconnect(_ link: BLEPeripheralLink, error: Error?)
    func bleSubscriptionFailed(_ link: BLEPeripheralLink, failure: BLELinkFailure)
    /// Services found and notifications on: the amplifier can be used
    func bleDidSubscribe(_ link: BLEPeripheralLink)
    func bleDidReceive(_ data: Data, from link: BLEPeripheralLink)
    func bleReadyToWriteWithoutResponse(_ link: BLEPeripheralLink)
    func bleWriteFailed(_ link: BLEPeripheralLink, error: Error)
}
