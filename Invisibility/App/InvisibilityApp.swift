import OSLog
import Sentry
import SwiftUI

@main
struct InvisibilityApp: App {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "InvisibilityApp")

    @AppStorage("showMenuBar") private var showMenuBar: Bool = true

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {}

    var body: some Scene {
        // Main app view is managed in delegate and WindowManager
        MenuBarExtra("Invisibility", image: "MenuBarIcon", isInserted: $showMenuBar) {
            MenubarView()
        }
        .menuBarExtraStyle(.menu)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.help) {
                Button("Invisibility Help") {
                    NSWorkspace.shared.open(URL(string: "https://help.invisibility.so")!)
                }
                .keyboardShortcut("?", modifiers: [.command])
            }

            // Send message
            CommandGroup(after: CommandGroupPlacement.saveItem) {
                Button("Send Message") {
                    Task { await MessageViewModel.shared.sendFromChat() }
                }
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
    }
}
