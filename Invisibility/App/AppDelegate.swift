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

    @AppStorage("onboardingViewed") private var onboardingViewed = false

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
        guard windowSuccess else {
            logger.error("Failed to set up window")
            AlertManager.shared.doShowAlert(title: "Error", message: "Failed to set up window")
            return
        }
        logger.debug("Window set up successfully")

        if !onboardingViewed {
            logger.debug("Onboarding not viewed")
            WindowManager.shared.hideWindow()
            OnboardingManager.shared.setupWindow()
        } else {
            logger.debug("Onboarding viewed")
            WindowManager.shared.showWindow()
        }
    }

    func application(_: NSApplication, open urls: [URL]) {
        for url in urls {
            // Parse and handle the URL as needed
            print("URL received: \(url)")
            // Example: Check the scheme and handle the URL
            if url.scheme == "invisibility", let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                // Perform actions based on the URL components, such as extracting a token
                if let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                    logger.debug("Received JWT Token: \(token)")
                    // Handle the authentication with the received token
                    UserManager.shared.token = token
                    Task {
                        await UserManager.shared.setup()
                    }
                } else {
                    logger.error("No token found in URL")
                    AlertManager.shared.doShowAlert(title: "Error", message: "No token found in URL. Please try again, or contact support.")
                }
            }
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
            // DispatchQueue.global(qos: .userInitiated).async {
            //     Task {
            //         if await ScreenRecorder.shared.pause() {
            //             self.shouldResumeRecording = true
            //             self.logger.debug("Paused recording")
            //         }
            //     }
            // }
        } else if notification.name == NSWorkspace.didWakeNotification {
            logger.debug("Woke up")
            // Task {
            //     if shouldResumeRecording {
            //         shouldResumeRecording = false
            //         await ScreenRecorder.shared.resume()
            //         logger.debug("Resumed recording")
            //     }
            // }
        } else {
            logger.warning("Some other event other than sleep/wake: \(notification.name.rawValue)")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }
}
