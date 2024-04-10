import SentrySwiftUI
import SwiftUI

struct MessageView: View {
    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var isDragActive: Bool = false

    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared

    @AppStorage("resized") private var resized: Bool = false

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var body: some View {
        let _ = Self._printChanges()
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                MessageScrollView()
                    .sentryTrace("ScrollView")

                Spacer()

                // Action Icons
                ChatButtonsView()
                    .sentryTrace("ChatButtonsView")
                    .frame(maxHeight: 40)

                Spacer()

                ChatFieldView()
                    .focused($promptFocused)
                    .onTapGesture {
                        promptFocused = true
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 10)
                    .scrollIndicators(.never)
                    .sentryTrace("ChatField")
            }
            .animation(AppConfig.snappy, value: chatViewModel.textHeight)
            .animation(AppConfig.snappy, value: chatViewModel.images)
            .animation(AppConfig.snappy, value: resized)
            .overlay(
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.2))
                    .opacity(isDragActive ? 1 : 0)
            )
            .border(isDragActive ? Color.blue : Color.clear, width: 5)
            .onDrop(of: [.fileURL], isTargeted: $isDragActive) { providers in
                MessageViewModel.shared.handleDrop(providers: providers)
            }
            .onAppear {
                promptFocused = true
            }
            .onChange(of: chatViewModel.images) {
                promptFocused = true
            }
            .onChange(of: chatViewModel.shouldFocusTextField) {
                if chatViewModel.shouldFocusTextField {
                    promptFocused = true
                    chatViewModel.shouldFocusTextField = false
                }
            }
        }
        .sentryTrace("MessageView")
    }
}
