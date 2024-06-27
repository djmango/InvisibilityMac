//
//  OnboardingManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/6/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import AppKit
import Combine
import Foundation
import KeyboardShortcuts
import OSLog
import PostHog
import SwiftUI

class OnboardingManager {
    static let shared = OnboardingManager()

    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "OnboardingManager")

    private var contentView = OnboardingView()
    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    @AppStorage("onboardingViewed") public var onboardingViewed = false

    private init() {}

    @MainActor
    public func startOnboarding() {
        onboardingViewed = false
        defer { PostHogSDK.shared.capture("start_onboarding") }
        WindowManager.shared.hideWindow()
        setupWindow()
    }

    @MainActor
    public func completeOnboarding() {
        defer { PostHogSDK.shared.capture("complete_onboarding") }
        onboardingViewed = true
        window?.close()
        WindowManager.shared.showWindow()
        Task {
            await ScreenshotManager.shared.askForScreenRecordingPermission()
        }
    }

    @MainActor
    public func setupWindow() {
        defer { PostHogSDK.shared.capture("setup_onboarding") }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.window = window

        window.contentView = NSHostingView(rootView: contentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.isMovableByWindowBackground = true
        window.orderFrontRegardless()

        let windowWidth: CGFloat = 1000
        let windowHeight: CGFloat = 650

        // Middle of the screen

        // Find the screen that contains the cursor
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
        guard let screen else { return }

        // let screenFrame = NSScreen.main?.visibleFrame
        let screenFrame = screen.visibleFrame

        let xPos = (screenFrame.midX) - windowWidth / 2
        let yPos = (screenFrame.midY) - windowHeight / 2

        // Create a CGRect that represents the desired window frame
        let windowRect = CGRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight)

        // Set the window frame
        window.setFrame(windowRect, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)
    }
}
