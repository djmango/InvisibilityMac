import OSLog
import Sentry
import SwiftUI

@main
struct InvisibilityApp: App {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "InvisibilityApp")

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        SharedModelContainer.shared = SharedModelContainer()
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .modelContext(SharedModelContainer.shared.mainContext)
        }
        .commands {
            // CommandGroup(replacing: CommandGroupPlacement.appInfo) {
            //     Button("About Invisibility") {
            //         NSApp.orderFrontStandardAboutPanel(nil)
            //     }
            //     .keyboardShortcut(",", modifiers: [.command, .shift])
            // }
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
        // Main app view is managed in delegate and WindowManager
        // MenuBarExtra("Invisibility", image: "MenuBarIcon", isInserted: $showMenuBarExtra) {
        //     MenuBarView()
        // }
        // .menuBarExtraStyle(.window)
    }
}
