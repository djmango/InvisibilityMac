import DockProgress
import OSLog
import SettingsKit
import SwiftUI
import TelemetryClient

@main
struct InvisibilityApp: App {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "GravityApp")

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @AppStorage("analytics") var analytics: Bool = true {
        didSet {
            if analytics != true {
                TelemetryManager.send("TelemetryDisabled")
            } else {
                TelemetryManager.send("TelemetryEnabled")
            }
        }
    }

    @AppStorage("userIdentifier") private var userIdentifier: String = ""
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true

    init() {
        SharedModelContainer.shared = SharedModelContainer()

        if analytics {
            if userIdentifier.isEmpty {
                userIdentifier = UUID().uuidString
            }

            let telemetryConfig = TelemetryManagerConfiguration(
                appID: "3F0E42B4-8F78-4047-B648-6C262EB5D9BE"
            )
            TelemetryManager.initialize(with: telemetryConfig)
            TelemetryManager.updateDefaultUser(to: userIdentifier)

            TelemetryManager.send("ApplicationLaunched")
        }

        Task {
            await WhisperManager.shared.setup()
        }

        DockProgress.style = .pie(color: .accent)
    }

    var body: some Scene {
        // WindowGroup {
        //     EmptyView()
        //         // Close just the window instantly
        //         .onAppear {
        //             if let window = NSApplication.shared.windows.first {
        //                 window.close()
        //             }
        //         }
        // }
        Settings {
            SettingsTab(.new(title: "Gravity", icon: .gearshape), id: "gravity") {
                SettingsSubtab(.new(title: "General", icon: .gearshape), id: "general") {
                    SettingsSubtab(.noSelection, id: "general") {
                        GeneralSettingsView().modelContext(SharedModelContainer.shared.mainContext)
                    }
                }
                SettingsSubtab(.new(title: "About", icon: .info), id: "about") {
                    SettingsSubtab(.noSelection, id: "about") {
                        AboutSettingsView()
                    }
                }
            }
        }
        // Main app view is managed in delegate and WindowManager
        MenuBarExtra("Gravity", image: "MenuBarIcon", isInserted: $showMenuBarExtra) {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
