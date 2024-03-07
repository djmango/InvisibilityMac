//
//  WindowManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/19/24.
//

import AppKit
import Combine
import Foundation
import KeyboardShortcuts
import OSLog
import SwiftUI

class InteractivePanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }
}

class WindowManager: ObservableObject {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "WindowManager")

    static let shared = WindowManager()

    private var contentView = AppView()
    private var window: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    private let animationDuration: TimeInterval = 0.2

    /// The current screen the window is on
    @Published var currentScreen: NSScreen?

    // We keep track of the messages so that we can have the min window height
    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModel.shared

    /// Whether the window is visible
    public var windowIsVisible: Bool {
        guard let window else { return false }
        return window.isVisible
    }

    /// Whether the window is on the screen with the cursor
    public var windowIsOnScreenWithCursor: Bool {
        let newScreen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
        if newScreen != self.currentScreen {
            return false
        } else {
            return true
        }
    }

    private init() {
        setupShortcuts()
    }

    private func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .summon) {
            // If we are just changing screens, don't toggle the window
            if self.windowIsOnScreenWithCursor {
                self.logger.debug("Toggling window")
                self.toggleWindow()
            } else {
                self.logger.debug("Changing screens")
                // Just move to the new screen
                self.positionWindowOnCursorScreen()
                self.showWindow()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .screenshot) {
            self.logger.debug("Taking screenshot")
            Task { await ScreenshotManager.shared.capture() }
            self.positionWindowOnCursorScreen()
        }
    }

    public func toggleWindow() {
        guard let window else { return }
        if window.isVisible == true {
            hideWindow()
        } else {
            showWindow()
        }
    }

    public func showWindow() {
        guard let window else { return }
        guard OnboardingManager.shared.onboardingViewed else { return }
        // Animate opacity
        window.alphaValue = 0
        positionWindowOnCursorScreen()
        ChatViewModel.shared.focusTextField()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            window.animator().alphaValue = 1
        }
    }

    public func hideWindow() {
        guard let window else { return }
        // Animate opacity
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
        })
    }

    public func setupWindow() -> Bool {
        logger.debug("Setting up window")

        // Actually do a panel
        let window = InteractivePanel(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.window = window

        window.contentView = NSHostingView(rootView: contentView)
        window.level = .mainMenu // Make the window float above all windows
        window.isOpaque = false // Enable transparency
        window.backgroundColor = NSColor.clear // Set background color to clear
        window.hasShadow = false // Optional: Disable shadow for a more "overlay" feel
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.orderFrontRegardless()

        logger.debug("Window set up")
        return true
    }

    private func positionWindowOnCursorScreen() {
        guard let window else { return }

        // Get the current mouse location
        let mouseLocation = NSEvent.mouseLocation

        // Find the screen that contains the cursor
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) }
        guard let screen else { return }
        currentScreen = screen

        // Define window width and the desired positioning
        let windowWidth: CGFloat = 400

        // Get the menu bar height to adjust the window position
        let menuBarHeight = NSStatusBar.system.thickness

        let windowHeight: CGFloat = screen.frame.height - menuBarHeight

        // Pin the window to the top left corner of the screen
        let xPos = screen.frame.origin.x
        let yPos = screen.frame.origin.y

        // Create a CGRect that represents the desired window frame
        let windowRect = CGRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight)

        // Set the window frame
        window.setFrame(windowRect, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)
    }
}
