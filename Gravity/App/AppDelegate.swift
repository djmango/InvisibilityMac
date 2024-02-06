//
//  AppDelegate.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/2/24.
//

import Cocoa
import Foundation
import OSLog
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "ai.grav.app", category: "AppDelegate")

    private var isAppActive = false
    // var statusBarItem: NSStatusItem!
    // var popover: NSPopover!

    func applicationDidFinishLaunching(_: Notification) {
        // Set up the observer for when the app becomes active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)

        // Set up the observer for when the app resigns active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidResignActive), name: NSApplication.didResignActiveNotification, object: nil)

        // // Create the status bar item
        // statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        // if let button = statusBarItem.button {
        //     // button.image = NSImage(systemSymbolName: "bell", accessibilityDescription: nil)
        //     button.image = NSImage(named: "MenuBarIcon")
        //     button.action = #selector(togglePopover(_:))
        // }

        // // Setup popover
        // popover = NSPopover()
        // popover.contentViewController = NSHostingController(rootView: PopoverView())
    }

    @objc func appDidBecomeActive(notification _: NSNotification) {
        isAppActive = true
    }

    @objc func appDidResignActive(notification _: NSNotification) {
        isAppActive = false
    }

    // @objc func togglePopover(_ sender: AnyObject?) {
    //     if popover.isShown {
    //         popover.performClose(sender)
    //     } else {
    //         if let button = statusBarItem.button {
    //             popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    //         }
    //     }
    // }

    // func updateIcon() {
    //     if let button = statusBarItem.button {
    //         button.image = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: nil) // Example icon change
    //     }
    // }
}
