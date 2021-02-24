//
//  AppDelegate.swift
//  Anykey
//
//  Created by Artem Chistyakov on 2/8/21.
//

import Cocoa
import Combine
import FileWatcher
import OSLog
import ShellOut
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var preferencesWindow: NSWindow!
    private var statusItem: NSStatusItem?
    private var keyboardListener: HotkeyListener!
    private var config: HotkeyConfig!
    private var fileWatcher: FileWatcher!
    private var fileObserver: AnyCancellable!
    private var notifications: Notifications!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        requireAccessibilityAccess()
        notifications = Notifications()
        installExampleConfig()
        loadConfig()
        setupFileWatcher()
        setupSettingsObserver()
        setupHotkeys()
        setupPreferences()
        setupStatusMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        fileObserver?.cancel()
    }

    private func setupHotkeys() {
        self.keyboardListener = HotkeyListener(onHotkey: { modifiers, key in
            if let hotkey = self.config.find(modifiers: modifiers, key: key) {
                DispatchQueue.global().async {
                    self.notifications.triggeredHotkey(hotkey: hotkey)
                    do {
                        try shellOut(to: hotkey.shellCommand)
                    } catch {
                        let error = error as! ShellOutError
                        os_log("Shell command error: %s", log: OSLog.default, type: .debug, error.message)
                        os_log("Shell command output: %s", log: OSLog.default, type: .error, error.output)
                    }
                }
                return true
            }
            return false
        })
    }

    @objc func showPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow.makeKeyAndOrderFront(nil)

    }

    private func setupStatusMenu() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let preferencesMenuItem = NSMenuItem(title: "Preferences", action: #selector(AppDelegate.showPreferences), keyEquivalent: ",")
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q")
        let menu = NSMenu()
        menu.addItem(preferencesMenuItem)
        menu.addItem(quitMenuItem)
        self.statusItem!.menu = menu
        let statusImage = NSImage(named: "anykey.statusbar")
        statusImage?.isTemplate = true
        self.statusItem!.button?.image = statusImage
    }
    
    private func configPath() -> String {
        return NSString(string: UserDefaults.standard.configPath).expandingTildeInPath
    }

    private func installExampleConfig() {
        guard NSString(string: configPath()).standardizingPath == NSString(string: configPathDefault).standardizingPath && !FileManager.default.fileExists(atPath: configPath()) else {
            return
        }
        FileManager.default.createFile(atPath: configPath(), contents: HotkeyConfig.example.data(using: .utf8))
    }
    
    private func loadConfig() {
        do {
            os_log("Reloading hotkey config at %s", log: OSLog.default, type: .debug, self.configPath())
            config = try HotkeyConfig(filePath: configPath())
        } catch let error as ConfigError {
            os_log("Error when loading the config at %s", log: OSLog.default, type: .error, self.configPath())
            notifications.configError(error: error)
        } catch {
            os_log("Unexpected error when loading the config at %s", log: OSLog.default, type: .error, self.configPath())
        }
        if (config == nil) { config = HotkeyConfig() }
    }
    
    private func setupFileWatcher() {
        if fileWatcher != nil {
            fileWatcher.stop()
        }

        fileWatcher = FileWatcher([configPath()])
        fileWatcher.queue = DispatchQueue.global()
        fileWatcher.callback = { event in
            guard event.path == self.configPath() && (event.fileCreated || event.fileModified) else { return }
            usleep(200000)
            self.loadConfig()
        }
        fileWatcher.start()
    }

    private func setupSettingsObserver() {
        fileObserver = UserDefaults.standard
            .publisher(for: \.configPath, options: [.new])
            .sink {
                os_log("New config file path: %s", log: OSLog.default, type: .info, $0)
                self.loadConfig()
                self.setupFileWatcher()
            }
    }

    private func setupPreferences() {
        let contentView = PreferencesView()
        preferencesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 200),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false)

        preferencesWindow.title = "Anykey Preferences"
        preferencesWindow.isReleasedWhenClosed = false
        preferencesWindow.center()
        preferencesWindow.setFrameAutosaveName("Anykey Preferences")
        preferencesWindow.contentView = NSHostingView(rootView: contentView)
        preferencesWindow.hidesOnDeactivate = true
    }

    private func requireAccessibilityAccess() {
        guard !AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() : true] as CFDictionary) else { return }

        let alert = NSAlert()
        alert.messageText = "Anykey requires Accessibility permissions"
        alert.informativeText = "Please enable in System Preference and re-launch the app."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        alert.runModal()

        NSApp.terminate(self)
    }
}
