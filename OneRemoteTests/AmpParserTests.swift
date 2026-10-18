import XCTest

final class AmpParserTests: XCTestCase {
    /// Builds a response like the amplifier sends it: '@' '+' <cmd> <length digit> <payload> '%'
    private func response(_ cmd: Character, _ payload: String) -> [UInt8] {
        Array("@+\(cmd)\(payload.count)\(payload)%".utf8)
    }

    func testVolume() {
        XCTAssertEqual(AmpParser.parse(response("V", "45")), .volume(45))
        XCTAssertEqual(AmpParser.parse(response("V", "00")), .volume(0))
        XCTAssertEqual(AmpParser.parse(response("V", "90")), .volume(90))
    }

    func testBalance() {
        XCTAssertEqual(AmpParser.parse(response("X", "10")), .balance(10))
        XCTAssertEqual(AmpParser.parse(response("X", "00")), .balance(0))
        XCTAssertEqual(AmpParser.parse(response("X", "20")), .balance(20))
    }

    func testBooleans() {
        XCTAssertEqual(AmpParser.parse(response("M", "0")), .mute(false))
        XCTAssertEqual(AmpParser.parse(response("M", "1")), .mute(true))
        XCTAssertEqual(AmpParser.parse(response("A", "0")), .avDirect(false))
        XCTAssertEqual(AmpParser.parse(response("A", "1")), .avDirect(true))
        XCTAssertEqual(AmpParser.parse(response("D", "1")), .hasDAC(true))
        XCTAssertEqual(AmpParser.parse(response("D", "0")), .hasDAC(false))
        XCTAssertEqual(AmpParser.parse(response("H", "1")), .headphones(true))
        XCTAssertEqual(AmpParser.parse(response("H", "0")), .headphones(false))
    }

    func testAnyValueOtherThanZeroCountsAsOn() {
        XCTAssertEqual(AmpParser.parse(response("M", "2")), .mute(true))
    }

    func testInputs() {
        XCTAssertEqual(AmpParser.parse(response("I", "1")), .input(.bluetooth))
        XCTAssertEqual(AmpParser.parse(response("I", "3")), .input(.optical))
        XCTAssertEqual(AmpParser.parse(response("I", "6")), .input(.aux5))
        XCTAssertEqual(AmpParser.parse(response("I", "8")), .input(.av))
    }

    func testUnknownInputCodeGivesNilInput() {
        XCTAssertEqual(AmpParser.parse(response("I", "9")), .input(nil))
    }

    func testFirmware() {
        XCTAssertEqual(AmpParser.parse(response("T", "21")), .firmware("2.1"))
        XCTAssertEqual(AmpParser.parse(response("T", "10")), .firmware("1.0"))
    }

    func testSerialNumberEndsBeforeTheEndCharacter() {
        let frame = Array("@+S8AB12CD34%".utf8)
        XCTAssertEqual(AmpParser.parse(frame), .serial("AB12CD34"))
    }

    func testRejectsMalformedFrames() {
        XCTAssertNil(AmpParser.parse([]))
        XCTAssertNil(AmpParser.parse(Array("@+V".utf8)))
        XCTAssertNil(AmpParser.parse(Array("#+V245%".utf8)), "wrong start character")
        XCTAssertNil(AmpParser.parse(Array("@+V14".utf8)), "volume with a single digit")
        XCTAssertNil(AmpParser.parse(response("V", "ab")), "non-numeric volume")
        XCTAssertNil(AmpParser.parse(response("X", "x1")), "non-numeric balance")
        XCTAssertNil(AmpParser.parse(Array("@+T11".utf8)), "firmware with a single digit")
        XCTAssertNil(AmpParser.parse(response("Z", "1")), "unknown command")
    }
}
