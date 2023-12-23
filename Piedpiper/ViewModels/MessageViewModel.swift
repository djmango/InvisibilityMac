import Combine
import Foundation
import OllamaKit
import SwiftData
import ViewState

@Observable
final class MessageViewModel: ObservableObject {
    private var generation: AnyCancellable?
    
    private var modelContext: ModelContext
    private var ollamaKit: OllamaKit
    
    var messages: [Message] = []
    var sendViewState: ViewState? = nil
    
    init(modelContext: ModelContext, ollamaKit: OllamaKit) {
        self.modelContext = modelContext
        self.ollamaKit = ollamaKit
    }
    
    deinit {
        self.stopGenerate()
    }
    
    func fetch(for chat: Chat) throws {
        let chatId = chat.id
        let predicate = #Predicate<Message>{ $0.chat?.id == chatId }
        let sortDescriptor = SortDescriptor(\Message.createdAt)
        let fetchDescriptor = FetchDescriptor<Message>(predicate: predicate, sortBy: [sortDescriptor])
        
        messages = try modelContext.fetch(fetchDescriptor)
    }
    
    @MainActor
    func send(_ message: Message) async {
        self.sendViewState = .loading
        
        messages.append(message)
        modelContext.insert(message)
        try? modelContext.saveChanges()
        
        if await ollamaKit.reachable() {
            // TODO Maybe guard this or something? to avoid ! nil crash
            let data = OkChatRequestData(model: message.model, messages: messages.map { $0.toChatMessage()! })
            
            let assistantMessage = Message(content: nil, role: .assistant)
            messages.append(assistantMessage)
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
                        self?.handleComplete()
                    case .failure(let error):
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
        
        messages[messages.endIndex - 1] = message
        try? modelContext.saveChanges()
        
        if await ollamaKit.reachable() {
            let data = OkChatRequestData(model: message.model, messages: messages.map { $0.toChatMessage()! })
 
            generation = ollamaKit.chat(data: data)
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.handleComplete()
                    case .failure(let error):
                        self?.handleError(error.localizedDescription)
                    }
                }, receiveValue: { [weak self] response in
                    self?.handleReceive(response)
                })
        } else {
            self.handleError(AppMessages.ollamaServerUnreachable)
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
       
        // Check if there are any messages and the last message is from an assistant and is not complete
        if let lastMessage = messages.last, lastMessage.role == .assistant && !lastMessage.done {
            // Append the new content to the last message
            if lastMessage.content.isNil { lastMessage.content = "" }
            lastMessage.content?.append(message.content)
        } else {
            // Create a new message with the received content
            let newMessage = Message(content: message.content, role: .assistant)
            messages.append(newMessage)
        }
        
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
        
        try? self.modelContext.saveChanges()
        self.sendViewState = nil
    }
    
    static func example(modelContainer: ModelContainer) -> MessageViewModel {
        let ollamaURL = URL(string: "http://localhost:11434")!
        let example = MessageViewModel(modelContext: ModelContext(modelContainer), ollamaKit: OllamaKit(baseURL: ollamaURL))
        return example
    }
}
