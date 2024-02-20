import AppKit
import Foundation
import KeyboardShortcuts
import SwiftData
import SwiftUI
import ViewCondition
import ViewState

@Observable
final class CommandViewModel: ObservableObject {
    static var shared = CommandViewModel()

    var isRenameChatViewPresented: Bool = false
    var isDeleteChatConfirmationPresented: Bool = false

    init() {
        KeyboardShortcuts.onKeyUp(for: .summon) {
            // First close all non-main windows
            for item in NSApp.windows {
                if item.windowController?.window?.identifier != NSUserInterfaceItemIdentifier("master") {
                    item.close()
                }
            }

            // Then open the main window
            NSApp.activate(ignoringOtherApps: true)

            // Move the window to the mouse location
            let mouseLocation = NSEvent.mouseLocation
            let window = NSApp.windows.first {
                $0.windowController?.window?.identifier == NSUserInterfaceItemIdentifier("master")
            }
            if let window {
                var frame = window.frame
                frame.origin = CGPoint(x: mouseLocation.x - frame.size.width / 2, y: mouseLocation.y - frame.size.height / 2)
                // frame.origin = CGPoint(x: 0, y: 0)
                // First get the screen the mouse is on
                // if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
                //     // Then get the frame of the screen
                //     let screenFrame = screen.frame
                //     // Then set the window's origin to the mouse location
                //     frame.origin = CGPoint(x: 0, y: 0)
                // }
                window.setFrame(frame, display: true)
            }
        }
    }
}
