import OllamaKit
import Sparkle
import SwiftUI
import SwiftData

class GlobalState: ObservableObject {
    @Published var activeChatID: UUID?
}

@main
struct PiedpiperApp: App {
    private var updater: SPUUpdater
    
    @StateObject private var globalState: GlobalState = GlobalState()
    @StateObject private var updaterViewModel: UpdaterViewModel
    @StateObject private var commandViewModel: CommandViewModel
    @StateObject private var ollamaViewModel: OllamaViewModel
    @StateObject private var chatViewModel: ChatViewModel
    
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
        let modelContext = sharedModelContainer.mainContext
        
        let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        updater = updaterController.updater
        
        let updaterViewModel = UpdaterViewModel(updater)
        _updaterViewModel = StateObject(wrappedValue: updaterViewModel)
        
        let commandViewModel = CommandViewModel()
        _commandViewModel = StateObject(wrappedValue: commandViewModel)
                
        let ollamaViewModel = OllamaViewModel(modelContext: modelContext)
        _ollamaViewModel = StateObject(wrappedValue: ollamaViewModel)
        
        let chatViewModel = ChatViewModel(modelContext: modelContext)
        _chatViewModel = StateObject(wrappedValue: chatViewModel)
        
        MessageViewModelManager.shared = MessageViewModelManager(modelContext: modelContext)
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(globalState)
                .environmentObject(updaterViewModel)
                .environmentObject(commandViewModel)
                .environmentObject(chatViewModel)
                .environmentObject(ollamaViewModel)
        }
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
                    commandViewModel.isAddChatViewPresented = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Button("Open File") {
                    guard let activeChatID = self.globalState.activeChatID else {
                        print("NOCHAT") // TODO make it spawn a chat
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
    }
}
