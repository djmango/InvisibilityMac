import Combine
import Foundation
import OllamaKit
import SwiftData
import ViewState
import CoreGraphics
import Vision

@Observable
final class MessageViewModel: ObservableObject {
    private var generation: AnyCancellable?
    
    private var chatID: UUID
    private var modelContext: ModelContext
    private let ollamaKit = OllamaKit.shared
    private var fileOpener: FileOpener
    
    var messages: [Message] = []
    var sendViewState: ViewState? = nil
    
    init(chatID: UUID, modelContext: ModelContext) {
        self.modelContext = modelContext
        self.chatID = chatID
        self.fileOpener = FileOpener()

    }
    
    deinit {
        self.stopGenerate()
    }
    
    func fetch(for chat: Chat) throws {
        let chatID = chat.id
        let predicate = #Predicate<Message>{ $0.chat?.id == chatID }
        let sortDescriptor = SortDescriptor(\Message.createdAt)
        let fetchDescriptor = FetchDescriptor<Message>(predicate: predicate, sortBy: [sortDescriptor])
        
        messages = try modelContext.fetch(fetchDescriptor)
    }
    
    @MainActor
    func send(_ message: Message) async {
        self.sendViewState = .loading
        
        messages.append(message)
        modelContext.insert(message)
        
        let assistantMessage = Message(content: nil, role: .assistant, chat: message.chat)
        messages.append(assistantMessage)
        modelContext.insert(message)
        
        try? modelContext.saveChanges()
        
        if await ollamaKit.reachable() {
            // Use compactMap to drop nil values and dropLast to drop the assistant message from the context we are sending to the LLM
            let data = OKChatRequestData(model: message.model, messages: messages.dropLast().compactMap { $0.toChatMessage() })
            
            generation = ollamaKit.chat(data: data)
                .handleEvents(
                        receiveSubscription: { _ in print("Received Subscription") },
                        receiveOutput: { _ in print("Received Output") },
                        receiveCompletion: { _ in print("Received Completion") },
                        receiveCancel: { print("Received Cancel") }
                    )
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        print("Success completion")
                        self?.handleComplete()
                    case .failure(let error):
                        print("Failure completion \(error)")
                        self?.handleError(error.localizedDescription)
                    }
                }, receiveValue: { [weak self] response in
                    self?.handleReceive(response)
                })
        } else {
            self.handleError(AppMessages.ollamaServerUnreachable)
        }
    }
    
    @MainActor
    func regenerate(_ message: Message) async {
        self.sendViewState = .loading
        let restarted = await OllamaKit.shared.restartBinaryAndWaitForAPI()
        if restarted {
            // Handle the case when the API restarts successfully
            print("API restarted successfully.")
            // Update the UI or proceed with the next steps
        } else {
            // Handle the failure case
            print("Failed to restart the API.")
            self.sendViewState = .error(message: "Failed to restart the API. Please try again later.")
            // Update the UI to show an error message
        }
        
        // For easy code reuse, essentially what we're doing here is resetting the state to before the message we want to regenerate was generated
        // So for that, we'll recreate the original send scenario, when the new user message was sent
        // We'll delete it the last two messages, the user message and the assistant message we want to regenerate
        // This assumes chat structure is always user -> assistant -> user
        
        if messages.count < 2 { return }
        messages.removeLast() // Removes the assistant message we are regenerating
        if let userMessage = messages.popLast() { // Removes the user message and presents a fresh send scenario
            await self.send(userMessage)
        }
    }
    
    func stopGenerate() {
        self.sendViewState = nil
        self.generation?.cancel()
        try? self.modelContext.saveChanges()
    }
    
    private func handleReceive(_ response: OKChatResponse) {
        if self.messages.isEmpty { return }
        guard let message = response.message else { return }
        guard let lastMessage = messages.last else { return }
        
        if lastMessage.content.isNil { lastMessage.content = "" }
        lastMessage.content?.append(message.content)
        
        self.sendViewState = .loading
    }
    
    private func handleError(_ errorMessage: String) {
        if self.messages.isEmpty { return }
        
        self.messages.last?.error = true
        self.messages.last?.done = false
        
        try? self.modelContext.saveChanges()
        self.sendViewState = .error(message: errorMessage)
    }
    
    private func handleComplete() {
        if self.messages.isEmpty { return }
        
        self.messages.last?.error = false
        self.messages.last?.done = true
        
        do {
            try self.modelContext.saveChanges()
        } catch {
            print("Error saving changes: \(error)")
        }

        self.sendViewState = nil
    }
    
    
    static func example(modelContainer: ModelContainer) -> MessageViewModel {
        let chat = Chat(name: "Example chat")
        let example = MessageViewModel(chatID: chat.id, modelContext: ModelContext(modelContainer))
        return example
    }
}

// @MARK Image Handler
extension MessageViewModel {
    
    // Public function that can be called to begin the file open process
    func openFile() {
        self.fileOpener.openFile(completionHandler: self.recognizeTextHandler)
    }
    
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        
        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        
        // Append the recognized strings to chat. Should design this better, just appending is dumb.
        let joined = recognizedStrings.joined(separator: " ")
        self.messages.append(Message(content: "Take a a look at this image for me", role: Role.user))
        self.messages.append(Message(content: "It says: \(joined)", role: Role.assistant))
    }

}
