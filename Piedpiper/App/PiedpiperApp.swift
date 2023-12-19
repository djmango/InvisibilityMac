import OllamaKit
import Sparkle
import SwiftUI
import SwiftData

@main
struct PiedpiperApp: App {
    private var updater: SPUUpdater
    
    @StateObject private var updaterViewModel: UpdaterViewModel
    @StateObject private var commandViewModel: CommandViewModel
    @StateObject private var ollamaViewModel: OllamaViewModel
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var messageViewModel: MessageViewModel
    @StateObject private var fileOpener: FileOpener
    
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
        
        let ollamaURL = URL(string: "http://localhost:11434")!
        let ollamaKit = OllamaKit(baseURL: ollamaURL)
                
        let ollamaViewModel = OllamaViewModel(modelContext: modelContext, ollamaKit: ollamaKit)
        _ollamaViewModel = StateObject(wrappedValue: ollamaViewModel)
        
        let messageViewModel = MessageViewModel(modelContext: modelContext, ollamaKit: ollamaKit)
        _messageViewModel = StateObject(wrappedValue: messageViewModel)
        
        let chatViewModel = ChatViewModel(modelContext: modelContext)
        _chatViewModel = StateObject(wrappedValue: chatViewModel)
        
        let fileOpener = FileOpener(messageViewModel: messageViewModel)
        _fileOpener = StateObject(wrappedValue: fileOpener)
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(updaterViewModel)
                .environmentObject(commandViewModel)
                .environmentObject(chatViewModel)
                .environmentObject(messageViewModel)
                .environmentObject(ollamaViewModel)
                .environmentObject(fileOpener)
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
                    fileOpener.openFile()
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
