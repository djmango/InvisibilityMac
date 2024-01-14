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

    // @AppStorage("selectedModel") private var selectedModel = "mistral:latest"

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

    @MainActor
    func addChat(completion: @escaping (Chat?) -> Void = { _ in }) {
        selectedChat = nil
        let chat = Chat()

        let selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? "mistral:latest"
        print("Selected model: \(selectedModel)")
        chat.model = OllamaViewModel.shared.fromName(selectedModel)

        print("Creating chat")

        Task {
            await runIfReachable {
                do {
                    try ChatViewModel.shared.create(chat)
                    self.selectedChat = chat
                    completion(chat)
                } catch {
                    print("Error creating chat: \(error)") // TODO: Show error
                    completion(nil)
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
