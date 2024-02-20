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
    private var shouldResumeRecording = false

    var window: NSWindow!
    private var windowManager = WindowManager.shared

    func applicationDidFinishLaunching(_: Notification) {
        // Set up the observer for when the app becomes active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)

        // Set up the observer for when the app resigns active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidResignActive), name: NSApplication.didResignActiveNotification, object: nil)

        // Set up the observer for when the system will sleep
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),
                                                          name: NSWorkspace.willSleepNotification, object: nil)

        // Set up the observer for when the system wakes
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),
                                                          name: NSWorkspace.didWakeNotification, object: nil)

        guard let screen = NSScreen.main else { return } // Get the main screen
        let screenHeight = screen.frame.height
        let screenWidth = screen.frame.width

        // Define window width and the desired positioning
        let windowWidth: CGFloat = 400

        // Calculate the x position to pin the window to the right side of the screen
        let xPos = screenWidth - windowWidth

        // Create a CGRect that represents the desired window frame
        let windowRect = CGRect(x: xPos, y: screenHeight, width: windowWidth, height: screenHeight)

        let contentView = AppView()

        window = NSApplication.shared.windows.first

        window.setFrame(windowRect, display: true)
        // window.setFrameAutosaveName("Main Window")
        // Move to right
        window.setFrameOrigin(NSPoint(x: 0, y: 0))
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        // window.setIsVisible(true) // Show the window
        window.styleMask = [.borderless] // Hide the title bar
        window.level = .floating // Make the window float above all regular windows
        window.isOpaque = false // Enable transparency
        window.backgroundColor = NSColor.clear // Set background color to clear
        window.hasShadow = true // Optional: Disable shadow for a more "overlay" feel
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden // Hide the title
    }

    @objc private func sleepListener(_ notification: Notification) {
        logger.info("Listening to sleep")

        if notification.name == NSWorkspace.willSleepNotification {
            logger.info("Going to sleep")
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    if await ScreenRecorder.shared.pause() {
                        self.shouldResumeRecording = true
                        self.logger.info("Paused recording")
                    }
                }
            }
        } else if notification.name == NSWorkspace.didWakeNotification {
            logger.info("Woke up")
            Task {
                if shouldResumeRecording {
                    shouldResumeRecording = false
                    await ScreenRecorder.shared.resume()
                    logger.info("Resumed recording")
                }
            }
        } else {
            logger.warning("Some other event other than sleep/wake: \(notification.name.rawValue)")
        }
    }

    @objc func appDidBecomeActive(notification _: NSNotification) {
        isAppActive = true
    }

    @objc func appDidResignActive(notification _: NSNotification) {
        isAppActive = false
    }
}
