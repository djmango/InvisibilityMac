import SentrySwiftUI
import SwiftUI

struct MainView: View {
    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var isDragActive: Bool = false
    @State private var xOffset: CGFloat = -1000

    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared
    @ObservedObject private var settingsViewModel = SettingsViewModel.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var historyViewModel = HistoryViewModel.shared

    @AppStorage("sideSwitched") private var sideSwitched: Bool = false

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var body: some View {
        // let _ = Self._printChanges()
        VStack(alignment: .center, spacing: 0) {
            ZStack {
                MessageScrollView()
                    .offset(x: !historyViewModel.isShowingHistory ? 0 : sideSwitched ? 1000 : -1000, y: 0)

                HistoryView()
                    .offset(x: 0, y: historyViewModel.isShowingHistory ? 0 : -1000)
                    .opacity(historyViewModel.isShowingHistory ? 1 : 0)

                Rectangle()
                    .foregroundColor(Color.white.opacity(0.001))
                    .onTapGesture {
                        // Dismiss settings when tapping on the chat in the background
                        if settingsViewModel.isShowingSettings {
                            settingsViewModel.isShowingSettings = false
                        }
                    }
                    .visible(if: settingsViewModel.isShowingSettings, removeCompletely: true)

                SettingsView()
                    .visible(if: settingsViewModel.isShowingSettings, removeCompletely: true)
            }
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.005), // Finish fading in
                        .init(color: .black, location: 0.995), // Start fading out
                        .init(color: .clear, location: 1.0),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Spacer()

            // Action Icons
            ChatButtonsView()
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
        }
        .animation(AppConfig.snappy, value: chatViewModel.textHeight)
        .animation(AppConfig.snappy, value: chatViewModel.images)
        .animation(AppConfig.snappy, value: screenRecorder.isRunning)
        .overlay(
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.2))
                .opacity(isDragActive ? 1 : 0)
                .onDrop(of: [.fileURL], isTargeted: $isDragActive) { providers in
                    InvisibilityFileManager.handleDrop(providers: providers)
                }
                // This is critical to make the reorderable model list work
                .hide(if: SettingsViewModel.shared.isShowingSettings, removeCompletely: true)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.snappy(duration: 0.3)) {
                    xOffset = 0
                }
            }
        }
        // .whatsNewSheet()
    }
}
