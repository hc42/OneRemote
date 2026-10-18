import Foundation

/// The LED scale of the volume display: 21 LEDs on a ring, mapped to the volume in dB.
/// Pure logic without UI, so it can be tested on its own.
enum VolumeScale {
    /// Number of LEDs on the ring
    static let ledCount = 21

    /// When turning up: from this dB value on the respective LED lights up (the first is index 0).
    /// Measured on the One HD, the scale follows no simple formula. The first LED applies from "-infinity".
    static let upDB: [Int] = [
        -1000, -88, -69, -54, -43, -36, -33, -30, -27, -23, -21,
        -18, -15, -12, -9, -6, -4, -3, -2, -1, 0,
    ]

    /// When turning down: at this dB value the display jumps to the respective LED. It stays there
    /// until the next value (that of the LED below) is reached. So the scale has a hysteresis.
    static let downDB: [Int] = [
        -90, -70, -55, -44, -37, -34, -31, -28, -25, -22, -19,
        -16, -13, -10, -7, -5, -4, -3, -2, -1, 0,
    ]

    /// Anchor points of the scale in dB: LED k starts at `knotsDB[k]` when turning up (the first one at 0 = -90 dB).
    /// Values in between are interpolated linearly.
    static let knotsDB: [Double] = [
        -90, -88, -69, -54, -43, -36, -33, -30, -27, -23, -21,
        -18, -15, -12, -9, -6, -4, -3, -2, -1, 0,
    ]

    /// Index of the lit LED. `previous` is the previous index and resolves the cases in which
    /// turning up and down show different LEDs (hysteresis).
    static func ledIndex(forVolume volume: Int, previous: Int) -> Int {
        let db = volume - AmpBLE.maxHardwareVolume
        let up = upDB.lastIndex(where: { $0 <= db }) ?? 0
        let down = downDB.firstIndex(where: { db <= $0 }) ?? (ledCount - 1)
        let lo = min(up, down), hi = max(up, down)
        return min(ledCount - 1, min(max(previous, lo), hi))
    }

    /// Position in LED units (0 to 20) for a dB value
    static func position(forDB db: Double) -> Double {
        let k = knotsDB
        guard db > k[0] else { return 0 }
        guard db < k[k.count - 1] else { return Double(k.count - 1) }
        let i = k.lastIndex(where: { $0 <= db }) ?? 0
        return Double(i) + (db - k[i]) / (k[i + 1] - k[i])
    }

    /// dB value for a position in LED units
    static func db(forPosition p: Double) -> Double {
        let k = knotsDB
        let i = min(k.count - 2, max(0, Int(p.rounded(.down))))
        return k[i] + (p - Double(i)) * (k[i + 1] - k[i])
    }
}
