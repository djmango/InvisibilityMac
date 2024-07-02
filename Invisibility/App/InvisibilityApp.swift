import OSLog
import SwiftUI

@main
struct InvisibilityApp: App {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "InvisibilityApp")

    @AppStorage("showMenuBar") private var showMenuBar: Bool = true

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {}

    var body: some Scene {
        // Main app view is managed in delegate and WindowManager
        MenuBarExtra("Invisibility", image: "MenuBarIcon", isInserted: $showMenuBar) {
            MenubarView()
        }
        .menuBarExtraStyle(.menu)
        .commands { AppMenuCommands() }
    }
}
