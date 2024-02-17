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

import IOKit.pwr_mgt

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "ai.grav.app", category: "AppDelegate")

    private var isAppActive = false
    private var shouldResumeRecording = false

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

    // var assertionID: IOPMAssertionID = 0
    // let assertionLevel = UInt32(kIOPMAssertionLevelOn)
    // let assertionName = "MyAppNeedsToPreventSleep" as CFString

    // func preventSystemSleep(reason: String = "Important Operation") {
    //     let success = IOPMAssertionCreateWithName(assertionName, assertionLevel, reason as CFString, &assertionID)
    //     if success == kIOReturnSuccess {
    //         print("Successfully prevented sleep")
    //     } else {
    //         print("Failed to prevent sleep")
    //     }
    // }

    // func allowSystemSleep() {
    //     let success = IOPMAssertionRelease(assertionID)
    //     if success == kIOReturnSuccess {
    //         print("Sleep is no longer prevented")
    //     } else {
    //         print("Failed to allow sleep")
    //     }
    // }
}
