import XCTest

/// Checks the German translation against the English texts in the source code.
/// The English texts are the keys (see docs/adr/0011-localization-english-source.md).
final class LocalizationTests: XCTestCase {
    /// Texts that are intentionally the same in both languages
    private let sameInBothLanguages: Set<String> = [
        "Balance", "AV Direct", "AV Direct: %@", "Firmware: %@", "Bluetooth",
    ]

    /// Calls whose first string argument is shown to the user and therefore needs a translation
    private let userFacingCalls = [
        "Text(", "Button(", "Label(", "Section(", "GroupBox(", "Toggle(", "Stepper(",
        "navigationTitle(", ".alert(", "String(localized: ", "caption(",
        "accessibilityName: ", "accessibilityUsage: ",
    ]

    private var repoRoot: URL {
        // <root>/OneRemoteTests/LocalizationTests.swift
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private var appSources: URL { repoRoot.appendingPathComponent("OneRemote") }

    private func germanStrings() throws -> [String: String] {
        let url = appSources.appendingPathComponent("Resources/de.lproj/Localizable.strings")
        let dictionary = NSDictionary(contentsOf: url) as? [String: String]
        return try XCTUnwrap(dictionary, "Localizable.strings could not be read: \(url.path)")
    }

    private func sourceLiterals() throws -> [SourceLiteral] {
        let enumerator = try XCTUnwrap(
            FileManager.default.enumerator(at: appSources, includingPropertiesForKeys: nil)
        )
        var all: [SourceLiteral] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let text = try String(contentsOf: url, encoding: .utf8)
            all += LiteralScanner(text).scan()
        }
        return all
    }

    /// %lld and %@ are both written as %@ in the source (an interpolation)
    private func normalized(_ s: String) -> String {
        s.replacingOccurrences(of: "%lld", with: "%@")
    }

    private func placeholders(in s: String) -> [String] {
        var found: [String] = []
        var rest = Substring(s)
        while let r = rest.range(of: "%") {
            let tail = rest[r.lowerBound...]
            if tail.hasPrefix("%@") {
                found.append("%@")
                rest = tail.dropFirst(2)
            } else if tail.hasPrefix("%lld") {
                found.append("%lld")
                rest = tail.dropFirst(4)
            } else {
                rest = tail.dropFirst(1)
            }
        }
        return found
    }

    func testGermanFileIsReadable() throws {
        XCTAssertFalse(try germanStrings().isEmpty)
    }

    func testTranslationsAreNotEmptyOrCopies() throws {
        for (key, value) in try germanStrings() {
            XCTAssertFalse(value.trimmingCharacters(in: .whitespaces).isEmpty, "empty translation for \"\(key)\"")
            XCTAssertNotEqual(key, value, "translation equals the key (remove the entry): \"\(key)\"")
        }
    }

    func testPlaceholdersMatchBetweenKeyAndTranslation() throws {
        for (key, value) in try germanStrings() {
            XCTAssertEqual(placeholders(in: key), placeholders(in: value), "placeholders differ for \"\(key)\"")
        }
    }

    func testEveryGermanKeyIsStillUsedInTheSource() throws {
        let used = Set(try sourceLiterals().map { normalized($0.text) })
        for key in try germanStrings().keys {
            XCTAssertTrue(used.contains(normalized(key)), "unused or misspelled key in Localizable.strings: \"\(key)\"")
        }
    }

    func testEveryUserFacingTextHasAGermanTranslation() throws {
        let keys = Set(try germanStrings().keys.map(normalized))
        var missing: [String] = []
        for literal in try sourceLiterals() {
            let text = normalized(literal.text)
            guard text.contains(where: { $0.isLetter }) else { continue }
            let prefix = literal.prefix.trimmingCharacters(in: .whitespacesAndNewlines)
            guard userFacingCalls.contains(where: { prefix.hasSuffix($0.trimmingCharacters(in: .whitespaces)) }) else { continue }
            if !keys.contains(text) && !sameInBothLanguages.contains(literal.text) {
                missing.append(literal.text)
            }
        }
        XCTAssertTrue(missing.isEmpty, "missing German translation for: \(Set(missing).sorted())")
    }
}

struct SourceLiteral {
    /// Content of the string literal; each interpolation is replaced by "%@"
    let text: String
    /// The code right before the opening quote
    let prefix: String
}

/// Finds the string literals in Swift source, including those nested in interpolations.
/// Line comments are skipped. Not a full Swift parser, but enough for this code base.
final class LiteralScanner {
    private let chars: [Character]
    private var i = 0
    private var literals: [SourceLiteral] = []

    init(_ source: String) {
        chars = Array(source)
    }

    func scan() -> [SourceLiteral] {
        while i < chars.count {
            if chars[i] == "/", i + 1 < chars.count, chars[i + 1] == "/" {
                while i < chars.count, chars[i] != "\n" { i += 1 }
            } else if chars[i] == "\"" {
                readLiteral()
            } else {
                i += 1
            }
        }
        return literals
    }

    /// `i` is at the opening quote; afterwards it is behind the closing quote
    private func readLiteral() {
        let start = i
        let prefix = String(chars[max(0, start - 60)..<start])
        i += 1
        var text = ""
        while i < chars.count {
            let ch = chars[i]
            if ch == "\\", i + 1 < chars.count {
                if chars[i + 1] == "(" {
                    i += 2
                    var depth = 1
                    while i < chars.count, depth > 0 {
                        if chars[i] == "\"" {
                            readLiteral()
                            continue
                        }
                        if chars[i] == "(" { depth += 1 } else if chars[i] == ")" { depth -= 1 }
                        i += 1
                    }
                    text += "%@"
                } else {
                    text.append(ch)
                    text.append(chars[i + 1])
                    i += 2
                }
            } else if ch == "\"" {
                i += 1
                literals.append(SourceLiteral(text: text, prefix: prefix))
                return
            } else {
                text.append(ch)
                i += 1
            }
        }
        literals.append(SourceLiteral(text: text, prefix: prefix))
    }
}
