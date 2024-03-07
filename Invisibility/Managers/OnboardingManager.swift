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
import SwiftUI

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    private let logger = Logger(subsystem: "so.invisibility.app", category: "OnboardingManager")

    private var contentView = OnboardingView()
    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    private let animationDuration: TimeInterval = 0.2

    @AppStorage("onboardingViewed") public var onboardingViewed = false

    private init() {}

    public func setupWindow() {
        logger.debug("Setting up onboarding")

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
        let windowHeight: CGFloat = 600

        // Middle of the screen
        let screenFrame = NSScreen.main?.frame
        let xPos = (screenFrame?.width ?? 0) / 2 - windowWidth / 2
        let yPos = (screenFrame?.height ?? 0) / 2 - windowHeight / 2

        // Create a CGRect that represents the desired window frame
        let windowRect = CGRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight)

        // Set the window frame
        window.setFrame(windowRect, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)

        logger.debug("Onboarding set up")
    }
}
