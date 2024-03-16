import OSLog
import SwiftUI

@main
struct InvisibilityApp: App {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "InvisibilityApp")

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true

    init() {
        SharedModelContainer.shared = SharedModelContainer()
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .modelContext(SharedModelContainer.shared.mainContext)
        }
        // Main app view is managed in delegate and WindowManager
        // MenuBarExtra("Invisibility", image: "MenuBarIcon", isInserted: $showMenuBarExtra) {
        //     MenuBarView()
        // }
        // .menuBarExtraStyle(.window)
    }
}
