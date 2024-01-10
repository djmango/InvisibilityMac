import ChatField
import SwiftData
import SwiftUI
import SwiftUIIntrospect
import ViewCondition
import ViewState

struct MessageView: View {
    private var chat: Chat

    @EnvironmentObject var globalState: GlobalState
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(ChatViewModel.self) private var chatViewModel: ChatViewModel
    @Environment(OllamaViewModel.self) private var ollamaViewModel: OllamaViewModel
    @EnvironmentObject private var imageViewModel: ImageViewModel

    @FocusState private var isEditorFocused: Bool
    @State private var viewState: ViewState? = nil

    // Prompt
    @FocusState private var promptFocused: Bool
    @State private var content: String = ""

    init(for chat: Chat) {
        self.chat = chat
    }

    var messageViewModel: MessageViewModel {
        MessageViewModelManager.shared.viewModel(for: chat)
    }

    var isGenerating: Bool {
        messageViewModel.sendViewState == .loading
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollViewProxy in
                List(messageViewModel.messages.indices, id: \.self) { index in
                    let message: Message = messageViewModel.messages[index]
                    // Generate the action for the message, if it is an assistant message.
                    let action: () -> Void = {
                        if message.role == .assistant {
                            {
                                regenerateAction(for: message)
                            }
                        } else {
                            {}
                        }
                    }()

                    // Generate the view for the individual message.
                    MessageListItemView(
                        message: message,
                        geometry: geometry,
                        regenerateAction: action
                    )
                    .assistant(message.role == .assistant)
                    .generating(message.content == nil && isGenerating)
                    .finalMessage(index == messageViewModel.messages.endIndex - 1)
                    .error(message.error, message: messageViewModel.sendViewState?.errorMessage)
                    .id(message)
                    .environmentObject(imageViewModel)
                }

                .onAppear {
                    scrollToBottom(scrollViewProxy)
                }
                .onChange(of: messageViewModel.messages) {
                    scrollToBottom(scrollViewProxy)
                }
                .onChange(of: messageViewModel.messages.last?.content) {
                    scrollToBottom(scrollViewProxy)
                }
                // TODO: Should add some kind of scroll lock, if at bottom, follow, otherwise allow free scroll.

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
            .task {
                initAction()
            }
            .onChange(of: chat) {
                initAction()
            }
        }
    }

    // MARK: - Actions

    private func initAction() {
        try? messageViewModel.fetch(for: chat)

        globalState.activeChat = chat

        isEditorFocused = true
    }

    private func sendAction() {
        guard messageViewModel.sendViewState == nil else { return }
        guard content.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else { return }

        let message = Message(content: content, role: .user, chat: chat)

        Task {
            try chatViewModel.modify(chat)
            content = ""
            await messageViewModel.send(message)
        }
    }

    private func regenerateAction(for message: Message) {
        guard messageViewModel.sendViewState == nil else { return }

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
