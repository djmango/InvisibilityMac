import Combine
import Foundation

class ChatButtonsViewModel: ObservableObject {
    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var isTranscribing: Bool = false
    @Published private(set) var isCommandPressed: Bool = false
    @Published private(set) var whoIsVisible: mainWindowView = .chat

    private var cancellables = Set<AnyCancellable>()

    private let chatViewModel: ChatViewModel = .shared
    private let mainWindowViewModel: MainWindowViewModel = .shared
    private let messageViewModel: MessageViewModel = .shared
    private let screenRecorder: ScreenRecorder = .shared
    private let voiceRecorder: VoiceRecorder = .shared
    private let screenshotManager: ScreenshotManager = .shared
    private let shortcutViewModel: ShortcutViewModel = .shared
    private let windowManager: WindowManager = .shared

    var isShowingHistory: Bool {
        whoIsVisible == .history
    }

    var isShowingMemory: Bool {
        whoIsVisible == .memory
    }

    init() {
        Task { @MainActor in
            screenRecorder.$isRunning
                .receive(on: DispatchQueue.main)
                .assign(to: \.isRecording, on: self)
                .store(in: &cancellables)

            voiceRecorder.$isRunning
                .receive(on: DispatchQueue.main)
                .assign(to: \.isTranscribing, on: self)
                .store(in: &cancellables)
        }

        mainWindowViewModel.$whoIsVisible
            .sink { [weak self] whoIsVisible in
                guard let self else { return }
                self.whoIsVisible = whoIsVisible
            }
            .store(in: &cancellables)

        messageViewModel.$isGenerating
            .receive(on: DispatchQueue.main)
            .assign(to: \.isGenerating, on: self)
            .store(in: &cancellables)

        shortcutViewModel.$isCommandPressed
            .receive(on: DispatchQueue.main)
            .assign(to: \.isCommandPressed, on: self)
            .store(in: &cancellables)
    }

    @MainActor func toggleRecording() {
        screenRecorder.toggleRecording()
    }

    @MainActor func toggleTranscribing() {
        voiceRecorder.toggleRecording()
    }

    @MainActor func newChat() {
        _ = chatViewModel.newChat()
    }

    func captureScreenshot() {
        Task {
            await screenshotManager.capture()
        }
    }

    @MainActor func changeView(to view: mainWindowView) {
        _ = mainWindowViewModel.changeView(to: view)
    }

    @MainActor func switchSide() {
        windowManager.switchSide()
    }

    @MainActor func stopGenerating() {
        messageViewModel.stopGenerating()
    }
}
