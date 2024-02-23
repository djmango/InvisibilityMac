import OSLog
import Sparkle
import SwiftUI
import ViewState

struct AppView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "AppView")

    @ObservedObject private var alertViewModel = AlertManager.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared

    @AppStorage("onboardingViewed") private var onboardingViewed = false

    var body: some View {
        MessageView()
            // ZStack {
            //     if onboardingViewed {
            //     } else {
            //         OnboardingView()
            //     }
            // }
            .pasteDestination(for: URL.self) { urls in
                guard let url = urls.first else { return }
                MessageViewModelManager.shared.messageViewModel.handleFile(url: url)
            }
            .onAppear {
                Task {
                    if await !ScreenRecorder.shared.canRecord {
                        logger.error("Screen recording is not available")
                    } else {
                        logger.info("Screen recording is available")
                    }
                }
            }
            // .handlesExternalEvents(matching: ["openURL:", "openFile:"])
            // .handlesExternalEvents(preferring: Set(arrayLiteral: "master"), allowing: Set(arrayLiteral: "*"))
            .modelContainer(SharedModelContainer.shared.modelContainer)
            .alert(isPresented: $alertViewModel.showAlert) {
                Alert(
                    title: Text(alertViewModel.alertTitle),
                    message: Text(alertViewModel.alertMessage),
                    dismissButton: .default(Text(alertViewModel.alertDismissText))
                )
            }
    }
}
