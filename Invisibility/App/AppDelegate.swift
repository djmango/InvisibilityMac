//
//  AppDelegate.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/2/24.
//

import Foundation
import OSLog
import PostHog
import Sentry
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "AppDelegate")

    private var shouldResumeRecording = false
    private var eventMonitor: Any?

    @AppStorage("onboardingViewed") private var onboardingViewed = false

    func applicationDidFinishLaunching(_: Notification) {
        SentrySDK.start { options in
            options.dsn = AppConfig.sentry_dsn
            options.tracesSampleRate = 0.05 // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            options.profilesSampleRate = 0.05
            options.swiftAsyncStacktraces = true
            options.enableMetricKit = true
        }
        PostHogSDK.shared.setup(PostHogConfig(apiKey: AppConfig.posthog_api_key))

        // Send an event with metadata on app launch
        sendLaunchEvent()

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: nil // Replace with your actual NSPanel instance
        )

        Task {
            await UserManager.shared.setup()
            let refresh_status = await UserManager.shared.refresh_jwt()
            if !refresh_status {
                logger.warning("Failed to refresh JWT token")
            }
        }

        let windowSuccess = WindowManager.shared.setupWindow()

        guard windowSuccess else {
            logger.error("Failed to set up window")
            return
        }
        // logger.debug("Window set up successfully")

        if !onboardingViewed {
            OnboardingManager.shared.startOnboarding()
        } else {
            WindowManager.shared.showWindow()
        }
    }

    func application(_: NSApplication, open urls: [URL]) {
        logger.debug("NSApp init called")
        for url in urls {
            // Parse and handle the URL as needed
            logger.debug("URL received: \(url)")
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
                } else if url == URL(string: "invisibility://paid") {
                    UserManager.shared.isPaid = true
                } else {
                    logger.error("No token found in URL")
                    logger.debug("URL: \(url)")
                    // Just run it anyway, good enough for now
                    Task {
                        await UserManager.shared.setup()
                    }
                }
            }
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        // If the window is visible and on the screen with the cursor, don't show it again
        if WindowManager.shared.windowIsVisible, WindowManager.shared.windowIsOnScreenWithCursor {
            // logger.debug("Window is visible and on screen with cursor, not showing again")
            return true
        }

        // Otherwise, show the window on the screen with the cursor
        WindowManager.shared.showWindow()
        // logger.debug("Window is not visible or not on screen with cursor, showing again")
        return false
    }

    @objc func appDidBecomeActive(notification _: NSNotification) {
        logger.debug("App did become active")
        // If the window is visible and on the screen with the cursor, don't show it again
        Task {
            if await WindowManager.shared.windowIsVisible, await WindowManager.shared.windowIsOnScreenWithCursor {
                return
            } else {
                // Otherwise, show the window on the screen with the cursor
                await WindowManager.shared.showWindow()
            }
        }
    }
    
    @MainActor
    @objc func panelDidBecomeKey(notification _: Notification) {
        // Move the switch logic here
        let hoverType: HoverItemType = HoverTrackerModel.shared.targetType

        guard let targetString = HoverTrackerModel.shared.targetItem,
              let target = UUID(uuidString: targetString)
        else {
            // Handle the case where the string was nil or not a valid UUID
            // logger.debug("Invalid or nil UUID hover target string")
            return
        }

        switch hoverType {
        case .chatImageDelete:
            logger.debug("Performing Chat Image Delete action")
            ChatFieldViewModel.shared.removeItem(id: target)
        case .chatPDFDelete:
            logger.debug("Performing Chat PDF Delete action")
            DispatchQueue.main.async {
                ChatFieldViewModel.shared.removeItem(id: target)
            }
        case .menuItem:
            logger.debug("Opening Menu Settings")
        // Implement menu move functionality
        case .chatImage:
            logger.debug("Handling Chat Image action")
            DispatchQueue.main.async {
                ChatFieldViewModel.shared.removeItem(id: target)
            }
        case .chatPDF:
            logger.debug("Handling Chat PDF action")
        // Implement chat PDF functionality
        case .nil_:
            logger.debug("No specific button action")
        }
    }

    @objc func appDidResignActive(notification _: NSNotification) {
        logger.debug("App did resign active")
    }

    @objc private func sleepListener(_ notification: Notification) {
        if notification.name == NSWorkspace.willSleepNotification {
            logger.debug("Going to sleep")
        } else if notification.name == NSWorkspace.didWakeNotification {
            logger.debug("Woke up")
        } else {
            logger.warning("Some other event other than sleep/wake: \(notification.name.rawValue)")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }

    private func sendLaunchEvent() {
        var metadata: [String: Any] = [:]

        // Mac RAM
        let ramSize = ProcessInfo.processInfo.physicalMemory
        metadata["mac_ram"] = ByteCountFormatter.string(fromByteCount: Int64(ramSize), countStyle: .file)

        // Mac CPU count
        metadata["cpu_count"] = ProcessInfo.processInfo.processorCount

        // Send the event with metadata
        PostHogSDK.shared.capture("App Launched", properties: metadata)
    }
}
