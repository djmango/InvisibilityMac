//
//  WindowManager.swift
//  Gravity
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
    private let logger = Logger(subsystem: "ai.grav.app", category: "WindowManager")

    static let shared = WindowManager()
    private var contentView = AppView()

    /// The current screen the window is on
    @Published var currentScreen: NSScreen?

    private var window: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        KeyboardShortcuts.onKeyUp(for: .summon) {
            // If we are just changing screens, don't toggle the window
            let newScreen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
            if newScreen != self.currentScreen {
                self.positionWindowOnCursorScreen()
            } else {
                if self.window?.isVisible == true {
                    self.window?.orderOut(nil)
                } else {
                    self.positionWindowOnCursorScreen()
                }
            }
        }
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

        positionWindowOnCursorScreen()
        return true
    }

    func positionWindowOnCursorScreen() {
        guard let window else { return }

        // Get the current mouse location
        let mouseLocation = NSEvent.mouseLocation

        // Find the screen that contains the cursor
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) }
        guard let screen else { return }
        currentScreen = screen

        // Define window width and the desired positioning
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = screen.frame.height

        // Get the menu bar height to adjust the window position
        let menuBarHeight = NSStatusBar.system.thickness

        // Pin the window to the top left corner of the screen
        let xPos = screen.frame.origin.x
        let yPos = screen.frame.origin.y

        // Create a CGRect that represents the desired window frame
        let windowRect = CGRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight - menuBarHeight)

        // Set the window frame
        window.setFrame(windowRect, display: true)
        window.makeKeyAndOrderFront(nil)
    }
}
