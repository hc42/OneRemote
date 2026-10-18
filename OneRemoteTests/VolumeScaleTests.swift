import XCTest

final class VolumeScaleTests: XCTestCase {
    /// dB at which each LED lights up when the volume is turned up from silence (measured on the device)
    private let upThresholds: [Int: Int] = [
        0: -90, 1: -88, 2: -69, 3: -54, 4: -43, 5: -36, 6: -33, 7: -30, 8: -27, 9: -23, 10: -21,
        11: -18, 12: -15, 13: -12, 14: -9, 15: -6, 16: -4, 17: -3, 18: -2, 19: -1, 20: 0,
    ]

    /// dB at which each LED lights up when the volume is turned down from the maximum (measured on the device)
    private let downThresholds: [Int: Int] = [
        0: -90, 1: -70, 2: -55, 3: -44, 4: -37, 5: -34, 6: -31, 7: -28, 8: -25, 9: -22, 10: -19,
        11: -16, 12: -13, 13: -10, 14: -7, 15: -5, 16: -4, 17: -3, 18: -2, 19: -1, 20: 0,
    ]

    func testTablesHaveOneEntryPerLED() {
        XCTAssertEqual(VolumeScale.ledCount, 21)
        XCTAssertEqual(VolumeScale.upDB.count, VolumeScale.ledCount)
        XCTAssertEqual(VolumeScale.downDB.count, VolumeScale.ledCount)
        XCTAssertEqual(VolumeScale.knotsDB.count, VolumeScale.ledCount)
    }

    func testTablesAreStrictlyIncreasing() {
        for table in [VolumeScale.upDB, VolumeScale.downDB] {
            for i in 1..<table.count {
                XCTAssertLessThan(table[i - 1], table[i])
            }
        }
        for i in 1..<VolumeScale.knotsDB.count {
            XCTAssertLessThan(VolumeScale.knotsDB[i - 1], VolumeScale.knotsDB[i])
        }
    }

    func testLEDThresholdsWhenTurningUp() {
        var previous = 0
        var firstDB: [Int: Int] = [:]
        for volume in 0...AmpBLE.maxHardwareVolume {
            let index = VolumeScale.ledIndex(forVolume: volume, previous: previous)
            XCTAssertGreaterThanOrEqual(index, previous, "the LED must not move back while turning up")
            previous = index
            if firstDB[index] == nil { firstDB[index] = volume - AmpBLE.maxHardwareVolume }
        }
        XCTAssertEqual(firstDB, upThresholds)
    }

    func testLEDThresholdsWhenTurningDown() {
        var previous = VolumeScale.ledCount - 1
        var firstDB: [Int: Int] = [:]
        for volume in stride(from: AmpBLE.maxHardwareVolume, through: 0, by: -1) {
            let index = VolumeScale.ledIndex(forVolume: volume, previous: previous)
            XCTAssertLessThanOrEqual(index, previous, "the LED must not move up while turning down")
            previous = index
            if firstDB[index] == nil { firstDB[index] = volume - AmpBLE.maxHardwareVolume }
        }
        XCTAssertEqual(firstDB, downThresholds)
    }

    func testHysteresisKeepsTheLastLEDWhereBothDirectionsDiffer() {
        // -89 dB (volume 1): turning up still shows the first LED, turning down already the second
        XCTAssertEqual(VolumeScale.ledIndex(forVolume: 1, previous: 0), 0)
        XCTAssertEqual(VolumeScale.ledIndex(forVolume: 1, previous: 1), 1)
        // -24 dB (volume 66)
        XCTAssertNotEqual(
            VolumeScale.ledIndex(forVolume: 66, previous: 0),
            VolumeScale.ledIndex(forVolume: 66, previous: 20)
        )
    }

    func testExtremes() {
        XCTAssertEqual(VolumeScale.ledIndex(forVolume: 0, previous: 0), 0)
        XCTAssertEqual(VolumeScale.ledIndex(forVolume: 0, previous: 20), 0)
        XCTAssertEqual(VolumeScale.ledIndex(forVolume: AmpBLE.maxHardwareVolume, previous: 0), 20)
        XCTAssertEqual(VolumeScale.ledIndex(forVolume: AmpBLE.maxHardwareVolume, previous: 20), 20)
    }

    func testPositionAtTheAnchors() {
        XCTAssertEqual(VolumeScale.position(forDB: -90), 0, accuracy: 1e-9)
        XCTAssertEqual(VolumeScale.position(forDB: -88), 1, accuracy: 1e-9)
        XCTAssertEqual(VolumeScale.position(forDB: -69), 2, accuracy: 1e-9)
        XCTAssertEqual(VolumeScale.position(forDB: 0), 20, accuracy: 1e-9)
    }

    func testPositionIsClampedOutsideTheScale() {
        XCTAssertEqual(VolumeScale.position(forDB: -120), 0, accuracy: 1e-9)
        XCTAssertEqual(VolumeScale.position(forDB: 12), 20, accuracy: 1e-9)
    }

    func testPositionInterpolatesBetweenAnchors() {
        // Half way between -88 and -69 dB
        XCTAssertEqual(VolumeScale.position(forDB: -78.5), 1.5, accuracy: 1e-9)
        XCTAssertEqual(VolumeScale.db(forPosition: 1.5), -78.5, accuracy: 1e-9)
    }

    func testPositionAndDBAreInverse() {
        for db in stride(from: -89.0, through: -1.0, by: 0.5) {
            XCTAssertEqual(VolumeScale.db(forPosition: VolumeScale.position(forDB: db)), db, accuracy: 1e-9)
        }
    }

    func testPositionIsMonotonic() {
        var last = -1.0
        for db in stride(from: -90.0, through: 0.0, by: 0.25) {
            let p = VolumeScale.position(forDB: db)
            XCTAssertGreaterThanOrEqual(p, last)
            last = p
        }
    }
}
