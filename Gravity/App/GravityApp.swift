import OllamaKit
import SettingsKit
import Sparkle
import SwiftData
import SwiftUI
import TelemetryClient

@main
struct GravityApp: App {
    private var updater: SPUUpdater
    public let modelContext: ModelContext

    @StateObject private var updaterViewModel: UpdaterViewModel
    @StateObject private var imageViewModel: ImageViewModel

    @AppStorage("analytics") private var analytics: Bool = true
    @AppStorage("userIdentifier") private var userIdentifier: String = ""

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Chat.self, Message.self, OllamaModel.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        updater = updaterController.updater

        let updaterViewModel = UpdaterViewModel(updater: updater)
        _updaterViewModel = StateObject(wrappedValue: updaterViewModel)

        modelContext = sharedModelContainer.mainContext

        let imageViewModel = ImageViewModel()
        _imageViewModel = StateObject(wrappedValue: imageViewModel)

        MessageViewModelManager.shared = MessageViewModelManager(modelContext: modelContext)
        ChatViewModel.shared = ChatViewModel(modelContext: modelContext)
        OllamaViewModel.shared = OllamaViewModel(modelContext: modelContext)

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
    }

    var body: some Scene {
        Window("Gravity", id: "master") {
            AppView()
                .environmentObject(updaterViewModel)
                .environmentObject(imageViewModel)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .modelContainer(sharedModelContainer)
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
                                print("TODO: Show error")
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
                SettingsSubtab(.noSelection, id: "general") { GeneralSettingsView() }
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
