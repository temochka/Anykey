//
//  NSUserKeyEquivalentsSync.swift
//  Anykey
//
//  Created by Artem Chistyakov on 4/9/21.
//

import Cocoa
import Foundation
import OSLog
import SwiftUI

extension Key {
    public var keyEquivalent: Character? {
        switch self {
        case .keypadClear: return Character(NSEvent.SpecialKey.clearLine.unicodeScalar)
        case .keypadEnter: return Character(NSEvent.SpecialKey.enter.unicodeScalar)
        case .`return`: return Character(NSEvent.SpecialKey.carriageReturn.unicodeScalar)
        case .tab: return Character(NSEvent.SpecialKey.tab.unicodeScalar)
        case .space: return " "
        case .delete: return Character(NSEvent.SpecialKey.delete.unicodeScalar)
        case .escape: return "\u{033}"
        case .command, .rightCommand: return "@"
        case .shift, .rightShift: return "$"
        case .capsLock: return nil
        case .option, .rightOption: return "~"
        case .control, .rightControl: return "^"
        case .function: return nil
        case .f17: return Character(NSEvent.SpecialKey.f17.unicodeScalar)
        case .volumeUp: return nil
        case .volumeDown: return nil
        case .mute: return nil
        case .f18: return Character(NSEvent.SpecialKey.f18.unicodeScalar)
        case .f19: return Character(NSEvent.SpecialKey.f19.unicodeScalar)
        case .f20: return Character(NSEvent.SpecialKey.f20.unicodeScalar)
        case .f5: return Character(NSEvent.SpecialKey.f5.unicodeScalar)
        case .f6: return Character(NSEvent.SpecialKey.f6.unicodeScalar)
        case .f7: return Character(NSEvent.SpecialKey.f7.unicodeScalar)
        case .f3: return Character(NSEvent.SpecialKey.f3.unicodeScalar)
        case .f8: return Character(NSEvent.SpecialKey.f8.unicodeScalar)
        case .f9: return Character(NSEvent.SpecialKey.f9.unicodeScalar)
        case .f11: return Character(NSEvent.SpecialKey.f11.unicodeScalar)
        case .f13: return Character(NSEvent.SpecialKey.f13.unicodeScalar)
        case .f16: return Character(NSEvent.SpecialKey.f16.unicodeScalar)
        case .f14: return Character(NSEvent.SpecialKey.f14.unicodeScalar)
        case .f10: return Character(NSEvent.SpecialKey.f10.unicodeScalar)
        case .f12: return Character(NSEvent.SpecialKey.f12.unicodeScalar)
        case .f15: return Character(NSEvent.SpecialKey.f15.unicodeScalar)
        case .help: return Character(NSEvent.SpecialKey.help.unicodeScalar)
        case .home: return Character(NSEvent.SpecialKey.home.unicodeScalar)
        case .pageUp: return Character(NSEvent.SpecialKey.pageUp.unicodeScalar)
        case .forwardDelete: return Character(NSEvent.SpecialKey.deleteForward.unicodeScalar)
        case .f4: return Character(NSEvent.SpecialKey.f4.unicodeScalar)
        case .end: return Character(NSEvent.SpecialKey.end.unicodeScalar)
        case .f2: return Character(NSEvent.SpecialKey.f2.unicodeScalar)
        case .pageDown: return Character(NSEvent.SpecialKey.pageDown.unicodeScalar)
        case .f1: return Character(NSEvent.SpecialKey.f1.unicodeScalar)
        case .leftArrow: return Character(NSEvent.SpecialKey.leftArrow.unicodeScalar)
        case .rightArrow: return Character(NSEvent.SpecialKey.rightArrow.unicodeScalar)
        case .downArrow: return Character(NSEvent.SpecialKey.downArrow.unicodeScalar)
        case .upArrow: return Character(NSEvent.SpecialKey.upArrow.unicodeScalar)
        case .a: return "a"
        case .b: return "b"
        case .c: return "c"
        case .d: return "d"
        case .e: return "e"
        case .f: return "f"
        case .g: return "g"
        case .h: return "h"
        case .i: return "i"
        case .j: return "j"
        case .k: return "k"
        case .l: return "l"
        case .m: return "m"
        case .n: return "n"
        case .o: return "o"
        case .p: return "p"
        case .q: return "q"
        case .r: return "r"
        case .s: return "s"
        case .t: return "t"
        case .u: return "u"
        case .v: return "v"
        case .w: return "w"
        case .x: return "x"
        case .y: return "y"
        case .z: return "z"
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .period: return "."
        case .quote: return "'"
        case .rightBracket: return "]"
        case .semicolon: return ";"
        case .slash: return "/"
        case .backslash: return "\\"
        case .comma: return ","
        case .equal: return "="
        case .grave: return "`"
        case .leftBracket: return "("
        case .minus: return "-"
        case .keypad0: return "0"
        case .keypad1: return "1"
        case .keypad2: return "2"
        case .keypad3: return "3"
        case .keypad4: return "4"
        case .keypad5: return "5"
        case .keypad6: return "6"
        case .keypad7: return "7"
        case .keypad8: return "8"
        case .keypad9: return "9"
        case .keypadDecimal: return "."
        case .keypadDivide: return "/"
        case .keypadEquals: return "="
        case .keypadMinus: return "-"
        case .keypadMultiply: return "*"
        case .keypadPlus: return "+"
        }
    }
}

extension NSEvent.ModifierFlags {
    public var keyEquivalent: String {
        let supportedModifiers: [(String, NSEvent.ModifierFlags)] = [
            ("@", .command),
            ("~", .option),
            ("^", .control),
            ("$", .shift),
            ("", .function),
        ]
        return supportedModifiers.map { (char, mod) in self.contains(mod) ? char : "" }.joined()
    }
}

class NSUserKeyEquivalentsSync {
    let config: HotkeyConfig

    init(_ config: HotkeyConfig) {
        self.config = config
    }

    func run() {
        for (bundleId, hotKeys) in config.menuHotkeys ?? [:] {
            if let appDefaults = UserDefaults(suiteName: bundleId) {
                let newShortcuts = Dictionary<String, String>(uniqueKeysWithValues: hotKeys.map { ($0.title, compileHotkey(key: $0.key, modifiers: $0.modifiers)) })
                appDefaults.set(newShortcuts as NSDictionary, forKey: "NSUserKeyEquivalents")
            } else {
                os_log("Invalid bundle id: %s", log: .default, type: .info, bundleId)
            }
        }
    }

    private func compileHotkey(key: Key, modifiers: NSEvent.ModifierFlags) -> String {
        return "\(modifiers.keyEquivalent)\(key.keyEquivalent.map { String($0) } ?? "")"
    }
}
