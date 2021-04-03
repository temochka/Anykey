//
//  SelectionGrabber.swift
//  Anykey
//
//  Created by Artem Chistyakov on 3/10/21.
//

import Cocoa
import Foundation

extension AXError: Error {

}

class AccessibilityClient {
    let element: AXUIElement

    init(_ element: AXUIElement) {
        self.element = element
    }

    func attributeNames() -> [String] {
        var attributeNamesRef: CFArray?
        AXUIElementCopyAttributeNames(element, &attributeNamesRef)

        guard attributeNamesRef != nil else { return [] }

        return attributeNamesRef as! [String]
    }

    func parameterizedAttributeNames() -> [String] {
        var parameterizedAttributeNamesRef: CFArray?
        AXUIElementCopyParameterizedAttributeNames(element, &parameterizedAttributeNamesRef)

        guard parameterizedAttributeNamesRef != nil else { return [] }

        return parameterizedAttributeNamesRef as! [String]
    }

    func attributeValue<T>(_ name: String) -> T? {
        var valueRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, name as CFString, &valueRef)
        guard valueRef != nil else { return nil }

        return (valueRef as! T)
    }

    func parameterizedAttributeValue<T>(_ name: String, _ parameter: AnyObject) -> T? {
        var valueRef: CFTypeRef?
        AXUIElementCopyParameterizedAttributeValue(element, name as CFString, parameter, &valueRef)
        guard valueRef != nil else { return nil }

        return (valueRef as! T)
    }

    func canSetAttribute(_ name: String) -> Bool {
        var status: DarwinBoolean = false
        AXUIElementIsAttributeSettable(element, name as CFString, &status)
        return status.boolValue
    }

    func setAttribute(_ name: String, _ value: AnyObject) throws {
        let error = AXUIElementSetAttributeValue(element, name as CFString, value)

        if error != .success {
            throw error
        }
    }
}

class SelectionGrabber {
    let systemWideElement: AccessibilityClient
    let kAXManualAccessibilityAttribute: String = "AXManualAccessibility"
    let kAXSelectedTextMarkerRange: String = "AXSelectedTextMarkerRange"
    let kAXAttributedStringForTextMarkerRange: String = "AXAttributedStringForTextMarkerRange"

    init() {
        systemWideElement = AccessibilityClient(AXUIElementCreateSystemWide())
    }

    func grab() -> NSAttributedString {
        guard let focusedElement = focusedElement() else { return NSAttributedString(string: "") }

        let attributeNames = focusedElement.attributeNames()
        print (attributeNames)

        let parameterizedAttributeNames = focusedElement.parameterizedAttributeNames()
        print (parameterizedAttributeNames)

        let selectedWebviewRange: CFTypeRef? =
            focusedElement.attributeValue(kAXSelectedTextMarkerRange)

        if let range = selectedWebviewRange {
            let selectedWebviewText: NSAttributedString? = focusedElement.parameterizedAttributeValue(kAXAttributedStringForTextMarkerRange, range)
            if selectedWebviewText != nil {
                return selectedWebviewText!
            }
        }

        guard let selectedTextValue: String = focusedElement.attributeValue(kAXSelectedTextAttribute) else { return NSAttributedString(string: "") }

        return NSAttributedString(string: selectedTextValue)
    }

    private func focusedElement() -> AccessibilityClient? {
        var focusedElement: AXUIElement? = systemWideElement.attributeValue(kAXFocusedUIElementAttribute)
        guard focusedElement == nil else { return AccessibilityClient(focusedElement!) }

        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let appRef: AXUIElement = AXUIElementCreateApplication(app.processIdentifier)
        let appClient = AccessibilityClient(appRef)

        if appClient.canSetAttribute(kAXManualAccessibilityAttribute) {
            try! appClient.setAttribute(kAXManualAccessibilityAttribute, kCFBooleanTrue)
        }

        focusedElement = systemWideElement.attributeValue(kAXFocusedUIElementAttribute)
        guard focusedElement == nil else { return AccessibilityClient(focusedElement!) }

        return nil
    }
}
