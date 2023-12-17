import OllamaKit
import Sparkle
import SwiftUI
import SwiftData

import CoreGraphics
import Vision
func recognizeTextHandler(request: VNRequest, error: Error?) {
    guard let observations =
            request.results as? [VNRecognizedTextObservation] else {
        return
    }
    let recognizedStrings = observations.compactMap { observation in
        // Return the string of the top VNRecognizedText instance.
        return observation.topCandidates(1).first?.string
    }
    
    // Process the recognized strings.
    print(recognizedStrings)
}

@main
struct PiedpiperApp: App {
    private var updater: SPUUpdater
    
    @State private var updaterViewModel: UpdaterViewModel
    @State private var commandViewModel: CommandViewModel
    @State private var ollamaViewModel: OllamaViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var messageViewModel: MessageViewModel
    
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
        _updaterViewModel = State(initialValue: updaterViewModel)
        
        let commandViewModel = CommandViewModel()
        _commandViewModel = State(initialValue: commandViewModel)
        
        let ollamaURL = URL(string: "http://localhost:11434")!
        let ollamaKit = OllamaKit(baseURL: ollamaURL)
                
        let ollamaViewModel = OllamaViewModel(modelContext: modelContext, ollamaKit: ollamaKit)
        _ollamaViewModel = State(initialValue: ollamaViewModel)
        
        let messageViewModel = MessageViewModel(modelContext: modelContext, ollamaKit: ollamaKit)
        _messageViewModel = State(initialValue: messageViewModel)
        
        let chatViewModel = ChatViewModel(modelContext: modelContext)
        _chatViewModel = State(initialValue: chatViewModel)
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(updaterViewModel)
                .environment(commandViewModel)
                .environment(chatViewModel)
                .environment(messageViewModel)
                .environment(ollamaViewModel)
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
                    FilePicker.openFile { url in
                        // Handle the selected file URL
                        if let url = url {
                            print(url)
                            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                                return
                            }

                            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                                return
                            }
                            
                            // Create a new image-request handler.
                            let requestHandler = VNImageRequestHandler(cgImage: cgImage)


                            // Create a new request to recognize text.
                            let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)


                            do {
                                // Perform the text-recognition request.
                                try requestHandler.perform([request])
                            } catch {
                                print("Unable to perform the requests: \(error).")
                            }
                        }
                    }
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
