//
//  AppDelegate.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/2/24.
//

import Foundation
import OSLog
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "ai.grav.app", category: "AppDelegate")

    private var isAppActive = false
    private var shouldResumeRecording = false

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

        let windowSuccess = WindowManager.shared.setupWindow()
        if !windowSuccess {
            logger.error("Failed to set up window")
            AlertManager.shared.doShowAlert(title: "Error", message: "Failed to set up window")
        }
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

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }
}
