import AppKit
import Foundation
import KeyboardShortcuts

@Observable
final class CommandViewModel: ObservableObject {
    var isAddChatViewPresented: Bool = false
    var isRenameChatViewPresented: Bool = false
    var isDeleteChatConfirmationPresented: Bool = false

    var selectedChat: Chat? = nil

    init() {
        KeyboardShortcuts.onKeyUp(for: .summon) {
            // First close all non-main windows
            NSApp.windows.forEach {
                if $0.windowController?.window?.identifier != NSUserInterfaceItemIdentifier("master") {
                    $0.close()
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
                window.setFrame(frame, display: true)
            }
        }
    }

    var chatToRename: Chat? {
        didSet {
            if chatToRename != nil {
                isRenameChatViewPresented = true
            }
        }
    }

    var chatToDelete: Chat? {
        didSet {
            if chatToDelete != nil {
                isDeleteChatConfirmationPresented = true
            }
        }
    }
}
