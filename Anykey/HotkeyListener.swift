//
//  KeyboardListener.swift
//  Anykey
//
//  Created by Artem Chistyakov on 2/10/21.
//

import Cocoa
import Foundation

typealias HotkeyCallback = ((NSEvent.ModifierFlags, UInt32) -> Bool)

class HotkeyListener {
    var eventLoop: CFRunLoopSource?
    var eventTap: CFMachPort!
    var callback: HotkeyCallback
    var selfPtr: Unmanaged<HotkeyListener>!

    init(onHotkey: @escaping HotkeyCallback) {
        callback = onHotkey
        selfPtr = Unmanaged.passRetained(self)
        eventTap = createTap()
        eventLoop = CFMachPortCreateRunLoopSource(nil, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), eventLoop!, CFRunLoopMode.commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true);
    }

    private func createTap() -> CFMachPort {
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: (1 << CGEventType.keyDown.rawValue),
            callback: { _, _, event, refcon in
                let foreignSelf = Unmanaged<HotkeyListener>.fromOpaque(refcon!).takeUnretainedValue()

                guard let nsEvent = NSEvent(cgEvent: event),
                      let deviceIndependentModifiers = Optional.some(nsEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)),
                      deviceIndependentModifiers != [],
                      foreignSelf.callback(deviceIndependentModifiers, UInt32(nsEvent.keyCode)) else {
                    return Unmanaged.passRetained(event)
                }

                return nil
            },
            userInfo: selfPtr.toOpaque()
        ) else {
            NSLog("Unable to invoke CGEvent.tapCreate. Please enable Accessibility for Anykey.app");
            exit(1)
        }
        return tap
    }
}
