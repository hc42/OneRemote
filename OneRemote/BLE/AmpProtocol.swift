import Foundation
import CoreBluetooth

/// BLE protocol of the ONE / ONE HD amplifier: UUIDs, command frames, inputs and value conversions.
enum AmpBLE {
    /// "MelodySmart" service of the BlueCreation module inside the amplifier
    static let service = CBUUID(string: "BC2F4CC6-AAEF-4351-9034-D66268E328F0")
    /// Characteristic for commands (write) and responses (notify)
    static let dataCharacteristic = CBUUID(string: "06D1E5E7-79AD-4A71-8FAA-373789F7D93C")
    /// Only devices whose name starts with "ONE" are listed
    static let namePrefix = "ONE"

    // Frame: '@' '+' <command> <length as ASCII digit> <payload ...> '%'
    static let start = UInt8(ascii: "@")
    static let filler = UInt8(ascii: "+")
    static let end = UInt8(ascii: "%")

    enum Cmd {
        static let avDirect = UInt8(ascii: "A")
        static let brightness = UInt8(ascii: "B")
        static let hasDAC = UInt8(ascii: "D")
        static let fetch = UInt8(ascii: "F")
        static let headphones = UInt8(ascii: "H")
        static let input = UInt8(ascii: "I")
        static let mute = UInt8(ascii: "M")
        static let serial = UInt8(ascii: "S")
        static let version = UInt8(ascii: "T")
        static let volume = UInt8(ascii: "V")
        static let balance = UInt8(ascii: "X")
    }

    /// These values are fetched after connecting.
    /// The balance (X) is not part of it, but its response format is handled in the parser.
    /// Order: what the controls need immediately first, serial number and firmware last.
    static let initialFetch: [UInt8] = [
        Cmd.input, Cmd.volume, Cmd.mute, Cmd.hasDAC,
        Cmd.headphones, Cmd.avDirect, Cmd.balance,
        Cmd.version, Cmd.serial,
    ]

    /// Highest volume value of the amplifier
    static let maxHardwareVolume = 90
    /// Default safety limit for the volume
    static let defaultMaxVolume = 60

    /// Display in dB (value minus 90, so 0 to 90 becomes -90 to 0 dB)
    static func dbText(_ volume: Int) -> String {
        let db = volume - maxHardwareVolume
        if db == 0 { return "0 dB" }
        return "\(db < 0 ? "\u{2212}" : "+")\(abs(db)) dB"
    }

    static func frame(_ body: [UInt8]) -> Data {
        Data([start, filler] + body + [end])
    }
}

/// Inputs of the One HD (DAC variant). The raw values are ASCII digits.
/// Order and labels match the device (confirmed on a One HD):
/// Code 6 is Aux 5, code 7 is Aux 6, and Phono (code 5) comes right before AV.
/// The order of the cases determines the order shown in the app.
enum AmpInput: UInt8, CaseIterable, Identifiable {
    case bluetooth = 0x31 // "1"
    case usbB = 0x32      // "2"
    case optical = 0x33   // "3"
    case spdif = 0x34     // "4"
    case aux5 = 0x36      // "6"
    case aux6 = 0x37      // "7"
    case phono = 0x35     // "5"
    case av = 0x38        // "8"

    var id: UInt8 { rawValue }

    var title: String {
        switch self {
        case .bluetooth: return "Bluetooth"
        case .usbB: return "USB"
        case .optical: return "3 · Optical"
        case .spdif: return "4 · S/PDIF"
        case .aux5: return "Aux 5"
        case .aux6: return "Aux 6"
        case .phono: return "Phono"
        case .av: return "AV"
        }
    }

    /// Symbol on the front panel (Bluetooth, USB, turntable); the other inputs use digits
    var symbolKind: String? {
        switch self {
        case .bluetooth: return "bluetooth"
        case .usbB: return "usb"
        case .phono: return "turntable"
        default: return nil
        }
    }

    /// Short label for the LED arc, modeled on the labels next to the source selector knob
    var shortTitle: String {
        switch self {
        case .bluetooth: return "@bluetooth"   // Starts with "@": symbol instead of text, see `InputSymbol`
        case .usbB: return "@usb"
        case .optical: return "3"
        case .spdif: return "4"
        case .aux5: return "5"
        case .aux6: return "6"
        case .phono: return "@turntable"
        case .av: return "AV"
        }
    }
}
