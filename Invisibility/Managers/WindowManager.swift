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
import PostHog
import SwiftUI

class InteractivePanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)

        DispatchQueue.main.async {
            withAnimation(AppConfig.snappy) {
                ShortcutViewModel.shared.isCommandPressed = event.modifierFlags.contains(.command)
            }
        }
    }

    // Listen for escape
    override func cancelOperation(_: Any?) {
        // If non-chat is open, close that instead
        if !MainWindowViewModel.shared.changeView(to: .chat) {
            WindowManager.shared.hideWindow()
        }
    }
}

@MainActor
class WindowManager {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "WindowManager")

    static let shared = WindowManager()

    static let defaultWidth: Int = 400
    static let resizeWidth: Int = 800
    public var maxWidth: Int = {
        guard let screen = NSScreen.main else { return 1000 } // Default value if no screen is found
        let screenWidth = Int(screen.frame.width)
        return screenWidth
    }()

    private var contentView = AppView()
    private var window: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    private let animationDuration: TimeInterval = 0.2

    /// The current screen the window is on
    private var currentScreen: NSScreen?

    @AppStorage("sideSwitched") private var sideSwitched: Bool = false
    @AppStorage("width") public var width: Int = Int(defaultWidth)

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
        ShortcutViewModel.shared.setupShortcuts()
    }

    public func resizeWindowToggle() {
        if width == WindowManager.defaultWidth {
            width = WindowManager.resizeWidth
        } else {
            width = WindowManager.defaultWidth
        }
        positionWindowOnCursorScreen(animate: true)
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
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            window.animator().alphaValue = 1
        }, completionHandler: {
            PostHogSDK.shared.capture("show_window")
        })
    }

    public func hideWindow(completion: (() -> Void)? = nil) {
        guard let window else { return }
        // Animate opacity
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            PostHogSDK.shared.capture("hide_window")
            completion?()
        })
    }

    public func switchSide() {
        sideSwitched.toggle()
        positionWindowOnCursorScreen(animate: true)
        PostHogSDK.shared.capture("switch_side", properties: ["sideSwitched": sideSwitched])
    }

    public func setupWindow() {
        // Actually do a panel
        let window = InteractivePanel(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: contentView)
        window.level = .floating // Make the window float above all windows except other floating windows (raycast, iterm, etc)
        window.isOpaque = false // Enable transparency
        window.backgroundColor = NSColor.clear // Set background color to clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle] // https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior
        window.hasShadow = false // This causes visual artifacts if true
        // window.isFloatingPanel = true // https://developer.apple.com/documentation/appkit/nspanel/1531901-isfloatingpanel
        // NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func resizeWindowToMouseX(_ mouseX: CGFloat) {
        guard let window = self.window, let screen = currentScreen else { return }

        var frame = window.frame
        let screenFrame = screen.visibleFrame

        // Constrain mouseX within allowable range
        let constrainedMouseX: CGFloat = if sideSwitched {
            // Right side: constrain mouseX between (screenFrame.maxX - maxWidth) and (screenFrame.maxX - defaultWidth)
            max(screenFrame.maxX - CGFloat(maxWidth), min(screenFrame.maxX - CGFloat(WindowManager.defaultWidth), mouseX))
        } else {
            // Left side: constrain mouseX between (screenFrame.minX + defaultWidth) and (screenFrame.minX + maxWidth)
            max(screenFrame.minX + CGFloat(WindowManager.defaultWidth), min(screenFrame.minX + CGFloat(maxWidth), mouseX))
        }

        if sideSwitched {
            // Right side: adjust left edge
            frame.size.width = screenFrame.maxX - constrainedMouseX
            frame.origin.x = constrainedMouseX
        } else {
            // Left side: adjust right edge
            frame.size.width = constrainedMouseX - screenFrame.minX
        }

        window.setFrame(frame, display: true, animate: false)
        self.width = Int(frame.size.width)
    }

    /// Position the window on the screen with the cursor
    public func positionWindowOnCursorScreen(animate: Bool = false) {
        guard let window else { return }

        // Get the current mouse location
        let mouseLocation = NSEvent.mouseLocation

        // Find the screen that contains the cursor
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) }
        guard let screen else { return }
        currentScreen = screen

        // Define window width and the desired positioning
        let windowWidth: CGFloat = CGFloat(width)

        // Get the menu bar height to adjust the window position
        let menuBarHeight = NSStatusBar.system.thickness

        let windowHeight: CGFloat = screen.frame.height - menuBarHeight - 15

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
        window.makeFirstResponder(nil)
        window.becomeFirstResponder()
    }
}
