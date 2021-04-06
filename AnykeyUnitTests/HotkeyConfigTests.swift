//
//  HotkeyConfigTests.swift
//  AnykeyUnitTests
//
//  Created by Artem Chistyakov on 4/4/21.
//

import Foundation
import XCTest
@testable import Anykey

class HotkeyConfigTests : XCTestCase {
    func testValid() throws {
        let config = try HotkeyConfig(url: fixtureUrl(name: "valid"))

        XCTAssertEqual(config.hotkeys.count, 226)
    }

    func testMissing() throws {
        var thrownError: Error?
        XCTAssertThrowsError(try HotkeyConfig(url: URL(fileURLWithPath: "/tmp/unlikely"))) {
            thrownError = $0
        }

        let configError = try XCTUnwrap(thrownError as? ConfigError)
        XCTAssertEqual(configError, ConfigError.access("The specified configuration file is missing."))

    }

    func testMalformed() throws {
        let error = try captureParsingError(fixtureName: "malformed")

        XCTAssertEqual(error, ConfigError.invalid("Invalid value for config root. The given data was not valid JSON."))
    }

    func testMissingHotkeys() throws {
        let error = try captureParsingError(fixtureName: "missing_hotkeys")

        XCTAssertEqual(error, ConfigError.invalid("Missing required key hotkeys."))
    }

    func testHotkeysIsNotArray() throws {
        let error = try captureParsingError(fixtureName: "hotkeys_is_not_array")

        XCTAssertEqual(error, ConfigError.invalid("Invalid value for hotkeys. Expected to decode Array<Any> but found a dictionary instead."))
    }

    func testEmptyModifiers() throws {
        let error = try captureParsingError(fixtureName: "empty_modifiers")

        XCTAssertEqual(error, ConfigError.invalid("Invalid value for modifiers. Found an empty array of modifiers."))
    }

    func testUnknownModifier() throws {
        let error = try captureParsingError(fixtureName: "unknown_modifier")

        XCTAssertEqual(error, ConfigError.invalid("Invalid value for modifiers. Unknown modifier super."))
    }

    func testUnknownKey() throws {
        let error = try captureParsingError(fixtureName: "unknown_key")

        XCTAssertEqual(error, ConfigError.invalid("Invalid value for key. Unknown key fuzz."))
    }

    private func captureParsingError(fixtureName: String) throws -> ConfigError {
        var thrownError: Error?
        XCTAssertThrowsError(try HotkeyConfig(url: fixtureUrl(name: fixtureName))) {
            thrownError = $0
        }

        return try XCTUnwrap(thrownError as? ConfigError)
    }

    private func fixtureUrl(name: String) throws -> URL {
        let bundle = Bundle(for: type(of: self))
        return try XCTUnwrap(bundle.url(forResource: name, withExtension: "json", subdirectory: "TestConfigs"))
    }
}
