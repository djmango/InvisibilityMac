import OllamaKit
import SettingsKit
import Sparkle
import SwiftData
import SwiftUI
import TelemetryClient

class GlobalState: ObservableObject {
    @Published var activeChat: Chat?
}

@main
struct GravityApp: App {
    private var updater: SPUUpdater

    @StateObject private var globalState: GlobalState = .init()

    @StateObject private var updaterViewModel: UpdaterViewModel
    @StateObject private var commandViewModel: CommandViewModel
    @StateObject private var ollamaViewModel: OllamaViewModel
    @StateObject private var chatViewModel: ChatViewModel
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

        print("Updater controller initialized")
        print(Bundle.main.infoDictionary ?? "No info dictionary")

        let modelContext = sharedModelContainer.mainContext

        let commandViewModel = CommandViewModel()
        _commandViewModel = StateObject(wrappedValue: commandViewModel)

        let ollamaViewModel = OllamaViewModel(modelContext: modelContext)
        _ollamaViewModel = StateObject(wrappedValue: ollamaViewModel)

        let chatViewModel = ChatViewModel(modelContext: modelContext)
        _chatViewModel = StateObject(wrappedValue: chatViewModel)

        let imageViewModel = ImageViewModel()
        _imageViewModel = StateObject(wrappedValue: imageViewModel)

        MessageViewModelManager.shared = MessageViewModelManager(modelContext: modelContext)

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
    }

    var body: some Scene {
        Window("Gravity", id: "master") {
            AppView()
                .environmentObject(globalState)
                .environmentObject(updaterViewModel)
                .environmentObject(commandViewModel)
                .environmentObject(chatViewModel)
                .environmentObject(ollamaViewModel)
                .environmentObject(imageViewModel)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updater.checkForUpdates()
                }
                // .disabled(!updaterViewModel.canCheckForUpdates)
            }

            CommandGroup(replacing: .newItem) {
                Button("New Chat") {
                    commandViewModel.isAddChatViewPresented = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open File") {
                    guard let activeChatID = globalState.activeChat else {
                        print("NOCHAT") // TODO: make it spawn a chat
                        return
                    }
                    MessageViewModelManager.shared.viewModel(for: activeChatID).openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(replacing: .textEditing) {
                if let selectedChat = commandViewModel.selectedChat {
                    ChatContextMenu(commandViewModel, for: selectedChat)
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
