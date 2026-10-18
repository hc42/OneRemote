import Foundation

/// A decoded response of the amplifier.
enum AmpEvent: Equatable {
    case avDirect(Bool)
    case hasDAC(Bool)
    case headphones(Bool)
    case mute(Bool)
    /// `nil` for an input code the app does not know
    case input(AmpInput?)
    case volume(Int)
    case balance(Int)
    /// For example "2.1"
    case firmware(String)
    case serial(String)
}

/// Decodes the notifications of the amplifier. Pure logic without state, so it can be tested on its own.
enum AmpParser {
    /// Returns `nil` for frames that are too short, do not start correctly,
    /// carry an unknown command or malformed digits.
    static func parse(_ d: [UInt8]) -> AmpEvent? {
        guard d.count >= 5, d[0] == AmpBLE.start else { return nil }
        let cmd = d[2]
        let b = d[4]
        let zero = UInt8(ascii: "0")

        switch cmd {
        case AmpBLE.Cmd.avDirect: return .avDirect(b != zero)
        case AmpBLE.Cmd.hasDAC: return .hasDAC(b != zero)
        case AmpBLE.Cmd.headphones: return .headphones(b != zero)
        case AmpBLE.Cmd.mute: return .mute(b != zero)
        case AmpBLE.Cmd.input: return .input(AmpInput(rawValue: b))
        case AmpBLE.Cmd.volume:
            guard d.count >= 6, let v = Int(String(decoding: d[4...5], as: UTF8.self)) else { return nil }
            return .volume(v)
        case AmpBLE.Cmd.balance:
            guard d.count >= 6, let v = Int(String(decoding: d[4...5], as: UTF8.self)) else { return nil }
            return .balance(v)
        case AmpBLE.Cmd.version:
            guard d.count >= 6 else { return nil }
            let s = String(decoding: d[4...5], as: UTF8.self)
            return .firmware(String(s.prefix(1)) + "." + String(s.dropFirst()))
        case AmpBLE.Cmd.serial:
            // The payload ends before the final end character
            guard d.count > 5 else { return nil }
            return .serial(String(decoding: d[4..<(d.count - 1)], as: UTF8.self))
        default:
            return nil
        }
    }
}
