import SwiftUI

struct AppMenuCommands: Commands {
    private let voiceRecorder: VoiceRecorder = .shared
    private let mainWindowViewModel: MainWindowViewModel = .shared
    private let windowManager: WindowManager = .shared

    var body: some Commands {
        CommandMenu("File") {
            Button("New") {
                DispatchQueue.main.async {
                    _ = ChatViewModel.shared.newChat()
                }
            }
            .keyboardShortcut("n")
            .keyboardShortcut(.delete, modifiers: [.command, .shift])

            Button("Open") {
                InvisibilityFileManager.openFile()
            }
            .keyboardShortcut("o")

            Button("Send Message") {
                Task { @MainActor in await MessageViewModel.shared.sendFromChat() }
            }
            .keyboardShortcut(.return, modifiers: [.command])
        }

        CommandMenu("View") {
            Button("Scroll to Bottom") {
                DispatchQueue.main.async {
                    MessageViewModel.shared.shouldScrollToBottom = true
                }
            }
            .keyboardShortcut("j", modifiers: [.command])

            Button("Resize") {
                DispatchQueue.main.async {
                    WindowManager.shared.resizeWindowToggle()
                }
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
        }

        CommandMenu("Chat") {
            Button("Microphone") {
                DispatchQueue.main.async {
                    voiceRecorder.toggleRecording()
                }
            }
            .keyboardShortcut("t", modifiers: [.command])

            Button("Chat History") {
                DispatchQueue.main.async {
                    if mainWindowViewModel.whoIsVisible == .history {
                        _ = mainWindowViewModel.changeView(to: .chat)
                    } else {
                        _ = mainWindowViewModel.changeView(to: .history)
                    }
                }
            }
            .keyboardShortcut("f", modifiers: [.command])

            Button("Memory") {
                DispatchQueue.main.async {
                    if mainWindowViewModel.whoIsVisible == .memory {
                        _ = mainWindowViewModel.changeView(to: .chat)
                    } else {
                        _ = mainWindowViewModel.changeView(to: .memory)
                    }
                }
            }
            .keyboardShortcut("m", modifiers: [.command])

            Button("Settings") {
                DispatchQueue.main.async {
                    if mainWindowViewModel.whoIsVisible == .settings {
                        _ = mainWindowViewModel.changeView(to: .chat)
                    } else {
                        _ = mainWindowViewModel.changeView(to: .settings)
                    }
                }
            }
            .keyboardShortcut(",", modifiers: [.command])

            Button("Switch Sides") {
                DispatchQueue.main.async {
                    windowManager.switchSide()
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }

        CommandGroup(replacing: CommandGroupPlacement.help) {
            Button("Invisibility Help") {
                NSWorkspace.shared.open(URL(string: "https://help.invisibility.so")!)
            }
            .keyboardShortcut("?", modifiers: [.command])
        }
    }
} 
