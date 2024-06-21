import SentrySwiftUI
import SwiftUI

struct MainView: View {
    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var isDragActive: Bool = false
    @State private var isDraggingResize = false
    @State private var xOffset: Int = 10000

    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared
    @ObservedObject private var mainWindowViewModel: MainWindowViewModel = MainWindowViewModel.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared

    @AppStorage("sideSwitched") private var sideSwitched: Bool = false
    @AppStorage("width") private var width: Int = Int(WindowManager.defaultWidth)

    var isShowingMessages: Bool {
        mainWindowViewModel.whoIsVisible == .chat
    }

    var isShowingHistory: Bool {
        mainWindowViewModel.whoIsVisible == .history
    }

    var isShowingSettings: Bool {
        mainWindowViewModel.whoIsVisible == .settings
    }

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var body: some View {
        // let _ = Self._printChanges()
        VStack(alignment: .center, spacing: 0) {
            ZStack {
                MessageScrollView()
                    .offset(x: isShowingMessages ? 0 : sideSwitched ? 1000 : -1000, y: 0)

                HistoryView()
                    .offset(x: 0, y: isShowingHistory ? 0 : -1000)
                    .opacity(isShowingHistory ? 1 : 0)

                SettingsView()
                    .offset(x: isShowingSettings ? 0 : sideSwitched ? 1000 : -1000, y: 0)
                    .opacity(isShowingSettings ? 1 : 0)
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
        // .gesture(
        //     DragGesture()
        //         .onChanged { value in
        //             withAnimation(AppConfig.snappy) {
        //                 WindowManager.shared.width = max(WindowManager.defaultWidth, min(WindowManager.shared.maxWidth, width - Int(value.translation.width)))
        //             }
        //         }
        // )
        .overlay(
            ChatDragResizeView(isDragging: $isDraggingResize)
                .gesture(
                    DragGesture()
                        .onChanged { _ in
                            let mouseLocation = NSEvent.mouseLocation
                            WindowManager.shared.resizeWindowToMouseX(mouseLocation.x)
                        }
                )
                .visible(if: !isShowingHistory, removeCompletely: true)
        )
        .overlay(
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.2))
                .opacity(isDragActive ? 1 : 0)
                .onDrop(of: [.fileURL], isTargeted: $isDragActive) { providers in
                    InvisibilityFileManager.handleDrop(providers: providers)
                }
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
        .offset(x: CGFloat(xOffset), y: 0)
        .onAppear {
            // Initial offset is set to 10000 to prevent the window from being visible guarenteed
            // For nice animation it should be about 500 more than the width of the window
            xOffset = -width - 500

            // If side is switched, invert the offset
            if sideSwitched {
                xOffset = xOffset * -1
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
