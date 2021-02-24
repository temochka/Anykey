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

func parseModifier(mod: String) throws -> NSEvent.ModifierFlags {
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
        throw ConfigError.invalid("Invalid modifier: \(mod)")
    }
}

struct Hotkey {
    let key: UInt32
    let modifiers: NSEvent.ModifierFlags
    let shellCommand: String
    let title: String
    let onlyIn: [String]

    init(json: [String: Any]) throws {
        guard let jsonTitle = json["title"] as? String else {
            throw ConfigError.invalid("invalid or missing field: title")
        }
        guard let jsonKey = json["key"] as? String else {
            throw ConfigError.invalid("invalid or missing field: key")
        }
        guard let jsonModifiers = json["modifiers"] as? [String] else {
            throw ConfigError.invalid("invalid or missing field: value")
        }
        guard let jsonShellCommand = json["shellCommand"] as? String else {
            throw ConfigError.invalid("invalid or missing field: shellCommand")
        }
        guard let jsonOnlyIn = json["onlyIn"] == nil ? Optional.some([]) : json["onlyIn"] as? [String] else {
            throw ConfigError.invalid("invalid field value: onlyIn")
        }
        key = Key(string: jsonKey)!.carbonKeyCode
        modifiers = NSEvent.ModifierFlags(try jsonModifiers.map(parseModifier))
        shellCommand = jsonShellCommand
        title = jsonTitle
        onlyIn = jsonOnlyIn
    }
}

class HotkeyConfig {
    static let example: String = """
{
    "hotkeys":
    [ { "title": "Anykey welcome"
      , "key": "a"
      , "modifiers": ["⌘", "⇧", "⌥", "⌃"]
      , "shellCommand": "say 'Thank you for using Anykey!'"
      , "onlyIn": []
      }
    ]
}
"""

    let hotkeys: [Hotkey]
    var isEmpty: Bool { hotkeys.isEmpty }

    init(filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            guard let hotkeysJson = json["hotkeys"] as? [[String: Any]] else {
                throw ConfigError.invalid("missing required top-level config field: \"hotkeys\"")
            }
            hotkeys = hotkeysJson.map { hotkeyJson in try! Hotkey(json: hotkeyJson) }
        } catch CocoaError.fileNoSuchFile, CocoaError.fileReadNoSuchFile {
            throw ConfigError.access("configuration file is missing")
        } catch CocoaError.fileLocking, CocoaError.fileReadCorruptFile, CocoaError.fileReadNoPermission, CocoaError.fileReadTooLarge {
            throw ConfigError.access("couldn’t read from the configuration file")
        } catch {
            os_log("Unexpected error %s when loading the config", log: OSLog.default, type: .error, error.localizedDescription)
            throw ConfigError.unknown("Unknown error when reading from the configuration file. Please check the log.")
        }
    }

    init() {
        hotkeys = []
    }

    func find(modifiers: NSEvent.ModifierFlags, key: UInt32) -> Hotkey? {
        let frontmostAppBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""

        return hotkeys
            .first(where: { hotkey in
                hotkey.key == key && hotkey.modifiers == modifiers && (hotkey.onlyIn.isEmpty || hotkey.onlyIn.contains(frontmostAppBundleId))

            })
    }
}
