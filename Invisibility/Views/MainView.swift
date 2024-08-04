import SwiftUI

struct MainView: View {
    @State private var isDragActive: Bool = false
    @State private var isDraggingResize = false
    @State private var xOffset: Int = 10000

    @ObservedObject private var mainWindowViewModel: MainWindowViewModel = MainWindowViewModel
        .shared

    @ObservedObject private var userManager: UserManager = UserManager.shared

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

    var isShowingMemory: Bool {
        mainWindowViewModel.whoIsVisible == .memory
    }

    var body: some View {
        // let _ = Self._printChanges()
        VStack(alignment: .center, spacing: 0) {
            ZStack {
                if userManager.isLoginStatusChecked {
                    if userManager.isLoggedIn {
                        MessageScrollView()
                            .visible(if: isShowingMessages, removeCompletely: true)

                        HistoryView()
                            .visible(if: isShowingHistory, removeCompletely: true)

                        MemoryView()
                            .visible(if: isShowingMemory, removeCompletely: true)

                        SettingsView()
                            .visible(if: isShowingSettings, removeCompletely: true)
                    } else {
                        LoginCardView()
                    }
                }
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
            .padding(.bottom, 5)

            // Action Icons
            ChatButtonsView()
                .padding(.bottom, 10)

            ChatFieldView()
                .padding(.bottom, 10)
        }
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
        .offset(x: CGFloat(xOffset), y: 0)
        .onAppear {
            // Initial offset is set to 10000 to prevent the window from being visible guarenteed
            // For nice animation it should be about 500 more than the width of the window
            xOffset = -width - 500

            // If side is switched, invert the offset
            if sideSwitched {
                xOffset = xOffset * -1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.snappy(duration: 0.3)) {
                    xOffset = 0
                }
            }
        }
    }
}
