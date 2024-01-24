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
    static var shared = CommandViewModel()

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
            AlertViewModel.shared.doShowAlert(title: "Error", message: "Could not connect to Ollama")
        }
    }

    func addChat() -> Chat? {
        DispatchQueue.main.async {
            self.selectedChat = nil
        }
        let chat = Chat()

        let selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? "mistral:latest"
        chat.model = OllamaViewModel.shared.fromName(selectedModel)

        do {
            try ChatViewModel.shared.create(chat)
            DispatchQueue.main.async {
                self.selectedChat = chat
            }
            return chat
        } catch {
            AlertViewModel.shared.doShowAlert(
                title: AppMessages.couldNotCreateChatTitle,
                message: AppMessages.couldNotCreateChatMessage
            )
            return nil
        }
    }

    func getOrCreateChat() -> Chat? {
        if let activeChat = selectedChat {
            activeChat
        } else {
            addChat()
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
