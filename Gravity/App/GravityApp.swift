import DockProgress
import OSLog
import SettingsKit
import Sparkle
import SwiftData
import SwiftUI
import TelemetryClient

@main
struct GravityApp: App {
    private let logger = Logger(subsystem: "ai.grav.app", category: "GravityApp")

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @ObservedObject private var updaterViewModel = UpdaterViewModel.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared

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
        Task {
            await LLMManager.shared.setup()
        }

        DockProgress.style = .pie(color: .accent)
    }

    var body: some Scene {
        Window("Gravity", id: "master") {
            AppView()
                .pasteDestination(for: URL.self) { urls in
                    guard let url = urls.first else { return }
                    MessageViewModelManager.shared.viewModel(for: CommandViewModel.shared.selectedChat).handleFile(url: url)
                }
                .onAppear {
                    Task {
                        if await !ScreenRecorder.shared.canRecord {
                            logger.error("Screen recording is not available")
                        } else {
                            logger.info("Screen recording is available")
                        }
                    }
                }
        }
        // .handlesExternalEvents(matching: ["openURL:", "openFile:"])
        // .handlesExternalEvents(preferring: Set(arrayLiteral: "master"), allowing: Set(arrayLiteral: "*"))
        .windowStyle(.hiddenTitleBar) // Hides the title bar for a more widget-like appearance
        // .windowToolbarStyle(UnifiedCompactWindowToolbarStyle()) // Optional: Adjusts the toolbar style if needed
        // .windowToolbarStyle(.unified(showsTitle: false))
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .modelContainer(SharedModelContainer.shared.modelContainer)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterViewModel.updater.checkForUpdates()
                }
                .disabled(!updaterViewModel.canCheckForUpdates)
            }

            CommandGroup(replacing: .newItem) {
                Button("New Chat") {
                    _ = CommandViewModel.shared.addChat()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open File") {
                    MessageViewModelManager.shared.viewModel(for: CommandViewModel.shared.selectedChat).openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(replacing: .textEditing) {
                ChatContextMenu(for: CommandViewModel.shared.selectedChat)
            }
        }
        .settings {
            SettingsTab(.new(title: "General", icon: .gearshape), id: "general") {
                SettingsSubtab(.noSelection, id: "general") {
                    GeneralSettingsView().modelContext(SharedModelContainer.shared.mainContext)
                }
            }
            .frame(width: 550, height: 200)
            // SettingsTab(.new(title: "Advanced", icon: .gearshape2), id: "advanced") {
            //     SettingsSubtab(.noSelection, id: "advanced") { AdvancedSettingsView() }
            // }
            // .frame(width: 550, height: 200)
            SettingsTab(.new(title: "About", icon: .info), id: "about") {
                SettingsSubtab(.noSelection, id: "about") {
                    AboutSettingsView()
                }
            }
            .frame(width: 550, height: 200)
        }
        MenuBarExtra("Gravity", image: "MenuBarIcon", isInserted: $showMenuBarExtra) {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
