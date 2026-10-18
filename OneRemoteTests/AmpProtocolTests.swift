import XCTest

final class AmpProtocolTests: XCTestCase {
    func testFrameWrapsTheBody() {
        let frame = AmpBLE.frame([AmpBLE.Cmd.mute, UInt8(ascii: "1"), UInt8(ascii: "1")])
        XCTAssertEqual(String(decoding: frame, as: UTF8.self), "@+M11%")
    }

    func testVolumeCommand() {
        let frame = AmpBLE.frame(AmpBLE.valueBody(AmpBLE.Cmd.volume, value: 45))
        XCTAssertEqual(String(decoding: frame, as: UTF8.self), "@+V245%")
    }

    func testValuesAreZeroPadded() {
        let frame = AmpBLE.frame(AmpBLE.valueBody(AmpBLE.Cmd.volume, value: 5))
        XCTAssertEqual(String(decoding: frame, as: UTF8.self), "@+V205%")
        let balance = AmpBLE.frame(AmpBLE.valueBody(AmpBLE.Cmd.balance, value: 10))
        XCTAssertEqual(String(decoding: balance, as: UTF8.self), "@+X210%")
    }

    func testFetchCommand() {
        let frame = AmpBLE.frame([AmpBLE.Cmd.fetch, UInt8(ascii: "1"), AmpBLE.Cmd.volume])
        XCTAssertEqual(String(decoding: frame, as: UTF8.self), "@+F1V%")
    }

    func testInitialFetchHasNoDuplicatesAndAsksForTheBalance() {
        XCTAssertEqual(Set(AmpBLE.initialFetch).count, AmpBLE.initialFetch.count)
        XCTAssertTrue(AmpBLE.initialFetch.contains(AmpBLE.Cmd.balance))
        XCTAssertTrue(AmpBLE.initialFetch.contains(AmpBLE.Cmd.volume))
        XCTAssertTrue(AmpBLE.initialFetch.contains(AmpBLE.Cmd.input))
    }

    func testDBText() {
        XCTAssertEqual(AmpBLE.dbText(90), "0 dB")
        XCTAssertEqual(AmpBLE.dbText(60), "\u{2212}30 dB")
        XCTAssertEqual(AmpBLE.dbText(0), "\u{2212}90 dB")
        XCTAssertEqual(AmpBLE.dbText(91), "+1 dB")
    }

    func testDefaultLimitIsBelowTheMaximum() {
        XCTAssertLessThan(AmpBLE.defaultMaxVolume, AmpBLE.maxHardwareVolume)
    }

    func testInputsAreInTheOrderOfTheDevice() {
        XCTAssertEqual(
            AmpInput.allCases,
            [.bluetooth, .usbB, .optical, .spdif, .aux5, .aux6, .phono, .av]
        )
    }

    func testInputCodesAreTheAsciiDigits() {
        XCTAssertEqual(AmpInput.bluetooth.rawValue, UInt8(ascii: "1"))
        XCTAssertEqual(AmpInput.aux5.rawValue, UInt8(ascii: "6"))
        XCTAssertEqual(AmpInput.aux6.rawValue, UInt8(ascii: "7"))
        XCTAssertEqual(AmpInput.phono.rawValue, UInt8(ascii: "5"))
        XCTAssertEqual(AmpInput.av.rawValue, UInt8(ascii: "8"))
        XCTAssertEqual(Set(AmpInput.allCases.map(\.rawValue)).count, AmpInput.allCases.count)
    }

    func testLabelsAreUniqueAndComplete() {
        XCTAssertEqual(Set(AmpInput.allCases.map(\.title)).count, AmpInput.allCases.count)
        for input in AmpInput.allCases {
            XCTAssertFalse(input.shortTitle.isEmpty)
        }
    }

    func testSymbolsMatchTheShortTitles() {
        for input in AmpInput.allCases {
            if let kind = input.symbolKind {
                XCTAssertEqual(input.shortTitle, "@" + kind)
            } else {
                XCTAssertFalse(input.shortTitle.hasPrefix("@"))
            }
        }
    }
}
