//
//  AppDelegate.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/2/24.
//

import Foundation
import OSLog
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "AppDelegate")

    private var shouldResumeRecording = false
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_: Notification) {
        // Set up the observer for when the app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        // Set up the observer for when the app resigns active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        // Set up the observer for when the system will sleep
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(sleepListener(_:)),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        // Set up the observer for when the system wakes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(sleepListener(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        let windowSuccess = WindowManager.shared.setupWindow()
        if !windowSuccess {
            logger.error("Failed to set up window")
            AlertManager.shared.doShowAlert(title: "Error", message: "Failed to set up window")
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        // If the window is visible and on the screen with the cursor, don't show it again
        if WindowManager.shared.windowIsVisible, WindowManager.shared.windowIsOnScreenWithCursor {
            return true
        }

        // Otherwise, show the window on the screen with the cursor
        WindowManager.shared.showWindow()
        return false
    }

    @objc func appDidBecomeActive(notification _: NSNotification) {
        logger.debug("App did become active")
        // If the window is visible and on the screen with the cursor, don't show it again
        if WindowManager.shared.windowIsVisible, WindowManager.shared.windowIsOnScreenWithCursor {
            return
        } else {
            // Otherwise, show the window on the screen with the cursor
            WindowManager.shared.showWindow()
        }
    }

    @objc func appDidResignActive(notification _: NSNotification) {
        logger.debug("App did resign active")
    }

    @objc private func sleepListener(_ notification: Notification) {
        if notification.name == NSWorkspace.willSleepNotification {
            logger.debug("Going to sleep")
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    if await ScreenRecorder.shared.pause() {
                        self.shouldResumeRecording = true
                        self.logger.debug("Paused recording")
                    }
                }
            }
        } else if notification.name == NSWorkspace.didWakeNotification {
            logger.debug("Woke up")
            Task {
                if shouldResumeRecording {
                    shouldResumeRecording = false
                    await ScreenRecorder.shared.resume()
                    logger.debug("Resumed recording")
                }
            }
        } else {
            logger.warning("Some other event other than sleep/wake: \(notification.name.rawValue)")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }
}
