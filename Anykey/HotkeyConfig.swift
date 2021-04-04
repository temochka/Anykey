//
//  HotkeyConfig.swift
//  Anykey
//
//  Created by Artem Chistyakov on 2/10/21.
//

import Cocoa
import Foundation
import OSLog

enum ConfigError : Error {
    case access(String)
    case invalid(String)
    case unknown(String)
}

extension NSEvent.ModifierFlags : Decodable {
    public init(from decoder: Decoder) throws {
        let jsonModifiers = try decoder.singleValueContainer().decode([String].self)

        guard !jsonModifiers.isEmpty else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Found an empty array of modifiers"))
        }

        self = NSEvent.ModifierFlags(try jsonModifiers.map { mod in
            switch mod {
            case "option", "opt", "alt", "⌥":
                return .option
            case "command", "cmd", "⌘":
                return .command
            case "control", "ctrl", "⌃":
                return .control
            case "shift", "⇧":
                return .shift
            case "fn", "function":
                return .function
            default:
                throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown modifier \(mod)"))
            }
        })
    }
}

extension Key : Decodable {
    public init(from decoder: Decoder) throws {
        let jsonKey = try decoder.singleValueContainer().decode(String.self)
        guard let knownKey = Key(string: jsonKey) else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown key \(jsonKey)"))
        }
        self = knownKey
    }
}

struct Hotkey : Decodable {
    let displayNotification: Bool?
    let key: Key
    let modifiers: NSEvent.ModifierFlags
    let shellCommand: String
    let title: String
    let onlyIn: [String]?
    let workingDirectory: String?
}

struct HotkeyConfig : Decodable {
    static let example: String = """
{
    "hotkeys":
    [ { "title": "Anykey welcome"
      , "displayNotification": true
      , "key": "a"
      , "modifiers": ["⌘", "⇧", "⌥", "⌃"]
      , "shellCommand": "say 'Thank you for using Anykey!'"
      , "onlyIn": []
      }
    ]
}
"""

    let hotkeys: [Hotkey]
    let workingDirectory: String?
    var isEmpty: Bool { hotkeys.isEmpty }

    init(filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self = try decoder.decode(HotkeyConfig.self, from: data)
        } catch CocoaError.fileNoSuchFile, CocoaError.fileReadNoSuchFile {
            throw ConfigError.access("configuration file is missing")
        } catch CocoaError.fileLocking, CocoaError.fileReadCorruptFile, CocoaError.fileReadNoPermission, CocoaError.fileReadTooLarge {
            throw ConfigError.access("couldn’t read from the configuration file")
        } catch let error as ConfigError {
            os_log("Error when loading the config: %s", log: OSLog.default, type: .error, error.localizedDescription)
            throw error
        } catch DecodingError.keyNotFound(let key, let context) {
            os_log("Config parse error: %s", context.debugDescription)
            throw ConfigError.invalid("Missing required key \(key.stringValue)")
        } catch DecodingError.valueNotFound(_, let context),
                DecodingError.typeMismatch(_, let context),
                DecodingError.dataCorrupted(let context) {
            os_log("Config parse error: %s", context.debugDescription)
            throw ConfigError.invalid("Invalid value for key \(context.codingPath.last?.stringValue ?? ""). \(context.debugDescription)")
        } catch {
            os_log("Unexpected error %s when loading the config", log: OSLog.default, type: .error, error.localizedDescription)
            throw ConfigError.unknown("Unknown error when reading from the configuration file. Please check the log.")
        }
    }

    init() {
        hotkeys = []
        workingDirectory = nil
    }

    func find(modifiers: NSEvent.ModifierFlags, key: UInt32) -> Hotkey? {
        let frontmostAppBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""

        return hotkeys
            .first(where: { hotkey in
                hotkey.key.carbonKeyCode == key &&
                    hotkey.modifiers == modifiers && hotkey.onlyIn.map { $0.contains(frontmostAppBundleId) } ?? true
            })
    }
}
