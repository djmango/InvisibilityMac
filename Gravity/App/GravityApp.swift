import OllamaKit
import SettingsKit
import Sparkle
import SwiftData
import SwiftUI
import TelemetryClient

@main
struct GravityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var updater: SPUUpdater

    @StateObject private var updaterViewModel: UpdaterViewModel
    @StateObject private var imageViewModel: ImageViewModel

    @AppStorage("analytics") private var analytics: Bool = true
    @AppStorage("userIdentifier") private var userIdentifier: String = ""

    init() {
        let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        updater = updaterController.updater

        let updaterViewModel = UpdaterViewModel(updater: updater)
        _updaterViewModel = StateObject(wrappedValue: updaterViewModel)

        SharedModelContainer.shared = SharedModelContainer()

        let imageViewModel = ImageViewModel()
        _imageViewModel = StateObject(wrappedValue: imageViewModel)

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

        OllamaKit.shared.runBinaryInBackground(withArguments: ["serve"], forceKill: true)
        Task {
            await WhisperViewModel.shared.setup()
        }
    }

    var body: some Scene {
        Window("Gravity", id: "master") {
            AppView()
                .environmentObject(updaterViewModel)
                .environmentObject(imageViewModel)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
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
                    CommandViewModel.shared.addChat()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open File") {
                    if let activeChat = CommandViewModel.shared.selectedChat {
                        MessageViewModelManager.shared.viewModel(for: activeChat).openFile()
                    } else {
                        CommandViewModel.shared.addChat { chat in
                            if let activeChat = chat {
                                MessageViewModelManager.shared.viewModel(for: activeChat).openFile()
                            } else {
                                AlertViewModel.shared.doShowAlert(title: "Error", message: "Could not open new chat")
                            }
                        }
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
            SettingsTab(.new(title: "Advanced", icon: .gearshape2), id: "advanced") {
                SettingsSubtab(.noSelection, id: "advanced") { AdvancedSettingsView() }
            }
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
