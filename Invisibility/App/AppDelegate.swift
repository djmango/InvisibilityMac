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

    private var isAppActive = false
    private var shouldResumeRecording = false
    private var eventMonitor: Any?

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

        // checkAccessibilityPermissions()
        // setupGlobalKeyListener()
    }

    // func setupGlobalKeyListener() {
    //     logger.info("Setting up global key listener")
    //     eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
    //         self.logger.info("Key pressed: \(event.keyCode)")
    //         if event.keyCode == 36 { // Enter key code
    //             DispatchQueue.main.async {
    //                 KeypressManager.shared.enterPressed = true
    //                 self.logger.info("Enter key pressed")
    //             }
    //         }
    //     }
    // }

    // func checkAccessibilityPermissions() {
    //     // let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
    //     // let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)

    //     let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
    //     let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)

    //     if accessibilityEnabled {
    //         setupGlobalKeyListener()
    //     } else {
    //         // Permissions not granted, the user is prompted, and you might need to handle this case.
    //         AlertManager.shared.doShowAlert(title: "Error", message: "Accessibility permissions not granted.")
    //         NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    //     }
    // }

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
