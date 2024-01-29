import DockProgress
import os
import SettingsKit
import Sparkle
import SwiftData
import SwiftUI
import TelemetryClient

@main
struct GravityApp: App {
    private let logger = Logger(subsystem: "ai.grav.app", category: "GravityApp")

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var updater: SPUUpdater

    @StateObject private var updaterViewModel: UpdaterViewModel
    // @StateObject private var imageViewModel: ImageViewModel

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

    init() {
        let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        updater = updaterController.updater

        let updaterViewModel = UpdaterViewModel(updater: updater)
        _updaterViewModel = StateObject(wrappedValue: updaterViewModel)

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
                .environmentObject(updaterViewModel)
                .pasteDestination(for: URL.self) { urls in
                    guard let url = urls.first else { return }

                    if let activeChat = CommandViewModel.shared.getOrCreateChat() {
                        MessageViewModelManager.shared.viewModel(for: activeChat).handleFile(url: url)
                    } else {
                        logger.error("Could not create chat")
                    }
                }
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .modelContainer(SharedModelContainer.shared.modelContainer)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updater.checkForUpdates()
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
                    if let activeChat = CommandViewModel.shared.getOrCreateChat() {
                        MessageViewModelManager.shared.viewModel(for: activeChat).openFile()
                    } else {
                        logger.error("Could not create chat")
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(replacing: .textEditing) {
                if let selectedChat = CommandViewModel.shared.selectedChat {
                    ChatContextMenu(for: selectedChat)
                }
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
            .frame(width: 550, height: 200)
            SettingsTab(.new(title: "About", icon: .info), id: "about") {
                SettingsSubtab(.noSelection, id: "about") {
                    AboutSettingsView()
                        .environmentObject(updaterViewModel)
                }
            }
            .frame(width: 550, height: 200)
        }
    }
}
