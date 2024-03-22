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

    override func flagsChanged(with event: NSEvent) {
        ShortcutViewModel.shared.modifierFlags = event.modifierFlags
    }

    // Listen for escape
    override func cancelOperation(_: Any?) {
        WindowManager.shared.hideWindow()
    }
}

@Observable
class WindowManager: ObservableObject {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "WindowManager")

    static let shared = WindowManager()

    private static let defaultWidth: CGFloat = 400
    private static let resizeWidth: CGFloat = 800

    private var contentView = AppView()
    private var window: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    private let animationDuration: TimeInterval = 0.2

    /// The current screen the window is on
    private var currentScreen: NSScreen?

    /// The width of the panel
    private var width: CGFloat = WindowManager.defaultWidth

    /// Persist the resized state
    @ObservationIgnored @AppStorage("resized") private var resized: Bool = false
    @ObservationIgnored @AppStorage("sideSwitched") private var sideSwitched: Bool = false

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
                Task {
                    await self.toggleWindow()
                }
            } else {
                self.logger.debug("Changing screens")
                // Just move to the new screen
                self.positionWindowOnCursorScreen()
                Task {
                    await self.showWindow()
                }
            }
        }

        KeyboardShortcuts.onKeyUp(for: .screenshot) {
            self.logger.debug("Taking screenshot")
            Task { await ScreenshotManager.shared.capture() }
            self.positionWindowOnCursorScreen()
        }
    }

    @MainActor
    public func toggleWindow() {
        guard let window else { return }
        if window.isVisible == true {
            hideWindow()
        } else {
            showWindow()
        }
    }

    @MainActor
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

    @MainActor
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

    @MainActor
    public func resizeWindow() {
        guard let window else { return }
        guard window.isVisible else { return }
        width = width == WindowManager.defaultWidth ? WindowManager.resizeWidth : WindowManager.defaultWidth
        resized = width == WindowManager.resizeWidth
        positionWindowOnCursorScreen(animate: true)
    }

    @MainActor
    public func switchSide() {
        sideSwitched.toggle()
        positionWindowOnCursorScreen(animate: true)
    }

    public func setupWindow() -> Bool {
        logger.debug("Setting up panel")

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

        logger.debug("Panel set up")
        return true
    }

    /// Position the window on the screen with the cursor
    private func positionWindowOnCursorScreen(animate: Bool = false) {
        guard let window else { return }

        // Get the current mouse location
        let mouseLocation = NSEvent.mouseLocation

        // Find the screen that contains the cursor
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) }
        guard let screen else { return }
        currentScreen = screen

        // Define window width and the desired positioning
        let windowWidth: CGFloat = if resized { WindowManager.resizeWidth } else { WindowManager.defaultWidth }

        // Get the menu bar height to adjust the window position
        let menuBarHeight = NSStatusBar.system.thickness

        let windowHeight: CGFloat = screen.frame.height - menuBarHeight

        // Determine the horizontal position
        let xPos: CGFloat = if sideSwitched {
            // Position the window on the right side of the screen
            screen.frame.origin.x + screen.frame.width - windowWidth
        } else {
            // Position the window on the left side of the screen
            screen.frame.origin.x
        }
        let yPos = screen.frame.origin.y

        // Create a CGRect that represents the desired window frame
        let windowRect = CGRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight)

        // Set the window frame
        window.setFrame(windowRect, display: true, animate: animate)
        window.makeKeyAndOrderFront(nil)
    }
}
