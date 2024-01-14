import AppKit
import Foundation
import KeyboardShortcuts
import OllamaKit

import SwiftData
import SwiftUI
import ViewCondition
import ViewState

@Observable
final class CommandViewModel: ObservableObject {
    var isRenameChatViewPresented: Bool = false
    var isDeleteChatConfirmationPresented: Bool = false

    var selectedChat: Chat? = nil

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
                window.setFrame(frame, display: true)
            }
        }
    }

    private func runIfReachable(_ function: @escaping () async -> Void) async {
        if await OllamaKit.shared.reachable() {
            await function()
        } else {
            print("Not reachable") // TODO: Show error
        }
    }

    func addChat() {
        // selectedChat = nil
        let chat = Chat()

        Task {
            await runIfReachable {
                do {
                    try ChatViewModel.shared.create(chat)
                    self.selectedChat = chat
                } catch {
                    print("Error creating chat: \(error)") // TODO: Show error
                }
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
