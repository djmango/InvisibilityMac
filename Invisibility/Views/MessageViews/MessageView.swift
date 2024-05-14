import SentrySwiftUI
import SwiftUI

struct MessageView: View {
    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var isDragActive: Bool = false
    @State private var xOffset: CGFloat = -1000

    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared
    @ObservedObject private var settingsViewModel = SettingsViewModel.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared

    @AppStorage("resized") private var resized: Bool = false
    @AppStorage("sideSwitched") private var sideSwitched: Bool = false

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var body: some View {
        let _ = Self._printChanges()
        VStack(alignment: .center, spacing: 0) {
            ZStack {
                MessageScrollView()
                    .sentryTrace("ScrollView")

                Rectangle()
                    .foregroundColor(Color.white.opacity(0.001))
                    .onTapGesture {
                        // Dismiss settings when tapping on the chat in the background
                        if settingsViewModel.showSettings {
                            settingsViewModel.showSettings = false
                        }
                    }
                    .visible(if: settingsViewModel.showSettings, removeCompletely: true)

                SettingsView()
                    .visible(if: settingsViewModel.showSettings, removeCompletely: true)
            }

            Spacer()

            CaptureView()
                .visible(if: screenRecorder.isRunning, removeCompletely: true)
                .padding(.top, -15)

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
        .animation(AppConfig.snappy, value: screenRecorder.isRunning)
        .overlay(
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.2))
                .opacity(isDragActive ? 1 : 0)
                .onDrop(of: [.fileURL], isTargeted: $isDragActive) { providers in
                    MessageViewModel.shared.handleDrop(providers: providers)
                }
                // This is critical to make the reorderable model list work
                .hide(if: SettingsViewModel.shared.showSettings, removeCompletely: true)
        )
        .border(isDragActive ? Color.blue : Color.clear, width: 5)
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
        .offset(x: xOffset, y: 0)
        .onAppear {
            // If side is switched, invert the offset
            if sideSwitched {
                xOffset = 1000
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.3)) {
                    xOffset = 0
                }
            }
        }
        .sentryTrace("MessageView")
        // .whatsNewSheet()
    }
}
