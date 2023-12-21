import SwiftUI
import SwiftData
import SwiftUIIntrospect
import ViewCondition
import ViewState
import ChatField

struct MessageView: View {
    private var chat: Chat
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(ChatViewModel.self) private var chatViewModel: ChatViewModel
    @Environment(MessageViewModel.self) private var messageViewModel: MessageViewModel
    @Environment(OllamaViewModel.self) private var ollamaViewModel: OllamaViewModel
    
    @FocusState private var isEditorFocused: Bool
    @State private var isEditorExpanded: Bool = false
    @State private var viewState: ViewState? = nil
    
    @FocusState private var promptFocused: Bool
    @State private var content: String = ""
    
    init(for chat: Chat) {
        self.chat = chat
    }
    
    var isGenerating: Bool {
        messageViewModel.sendViewState == .loading
    }
    
    var body: some View {
            ScrollViewReader { scrollViewProxy in
//                List(messageViewModel.messages, id: \.self) { message in
//                    let index = messageViewModel.messages.firstIndex(where: { $0.id == message.id }) ?? 0
//                                    
//                    MessageListItemView(text: message.content ?? "", role: message.role ?? Role.user)
//                        .assistant(message.role == .assistant)
//                        .generating(isGenerating)
//                        .finalMessage(index == messageViewModel.messages.endIndex - 1)
//                        .error(message.error, message: messageViewModel.sendViewState?.errorMessage)
//                        .id(message)
//                }
                List(messageViewModel.messages.indices, id: \.self) { index in
                    let message = messageViewModel.messages[index]
                        
                    MessageListItemView(text: message.content ?? "", role: message.role ?? Role.assistant)
                        .assistant(message.role == .assistant)
                        .generating(message.content.isNil && isGenerating)
                        .finalMessage(index == messageViewModel.messages.endIndex - 1)
                        .error(message.error, message: messageViewModel.sendViewState?.errorMessage)
                        .id(message)
                }

                .onAppear {
                    scrollToBottom(scrollViewProxy)
                }
                .onChange(of: messageViewModel.messages) {
                    scrollToBottom(scrollViewProxy)
                }
//                .onChange(of: messageViewModel.messages.last?.content) {
//                    scrollToBottom(scrollViewProxy)
//                }
                
                HStack(alignment: .bottom) {
                    ChatField("Message", text: $content, action: sendAction)
                        .textFieldStyle(CapsuleChatFieldStyle())
                        .focused($promptFocused)
                    
                    Button(action: sendAction) {
                        Image(systemName: "paperplane.fill")
                            .padding(8)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .help("Send message")
                    .hide(if: isGenerating, removeCompletely: true)
                    
                    Button(action: messageViewModel.stopGenerate) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help("Stop generation")
                    .visible(if: isGenerating, removeCompletely: true)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                .padding(.horizontal)
            }
            .navigationTitle(chat.name)
            .navigationSubtitle(chat.model?.name ?? "")
            .task {
                initAction()
            }
            .onChange(of: chat) {
                initAction()
            }
        }
    
    // MARK: - Actions
    private func initAction() {
        try? messageViewModel.fetch(for: chat)
        
        isEditorFocused = true
    }
    
    private func sendAction() {
        guard messageViewModel.sendViewState.isNil else { return }
        guard content.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else { return }
        
        let message = Message(content: content, role: Role.user)
        message.chat = chat
        
        Task {
            try chatViewModel.modify(chat)
            content = ""
            await messageViewModel.send(message)
        }
    }
    
    private func regenerateAction(for message: Message) {
        guard messageViewModel.sendViewState.isNil else { return }
        
        message.done = false
        
        Task {
            try chatViewModel.modify(chat)
            await messageViewModel.regenerate(message)
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard messageViewModel.messages.count > 0 else { return }
        let lastIndex = messageViewModel.messages.count - 1
        let lastMessage = messageViewModel.messages[lastIndex]
        
        proxy.scrollTo(lastMessage, anchor: .bottom)
    }
}

var mockModelContainer: ModelContainer {
        do {
            let schema = Schema([Chat.self, Message.self, OllamaModel.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("ModelContainer initialization failed: \(error)")
        }
    }

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
            MessageView(for: Chat.example())
                .environmentObject(ChatViewModel.example(modelContainer: mockModelContainer, chats: [Chat.example()]))
                .environmentObject(MessageViewModel.example(modelContainer: mockModelContainer))
                .environmentObject(OllamaViewModel.example(modelContainer: mockModelContainer))
    }
}
