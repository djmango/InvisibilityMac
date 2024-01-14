//
//  AppDelegate.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/2/24.
//

import Cocoa
import Foundation
import OllamaKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var isAppActive = false

    func applicationDidFinishLaunching(_: Notification) {
        // Set up the observer for when the app becomes active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)

        // Set up the observer for when the app resigns active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidResignActive), name: NSApplication.didResignActiveNotification, object: nil)

        // Task {
        //     await ModelWarmer.shared.warm()
        // }
    }

    @objc func appDidBecomeActive(notification _: NSNotification) {
        isAppActive = true
        // print("App became active")
        // Task {
        //     await ModelWarmer.shared.warm()
        // }
    }

    @objc func appDidResignActive(notification _: NSNotification) {
        isAppActive = false
        // print("App became inactive")
    }

    func applicationWillTerminate(_: Notification) {
        print("App will terminate")
        OllamaKit.shared.terminateBinaryProcess()
    }
}
