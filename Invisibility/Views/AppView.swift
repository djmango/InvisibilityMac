import OSLog
import Sparkle
import SwiftUI

struct AppView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "AppView")

    @ObservedObject private var alertViewModel = AlertManager.shared

    @AppStorage("onboardingViewed") private var onboardingViewed = false

    var body: some View {
        MessageView()
            .pasteDestination(for: URL.self) { urls in
                guard let url = urls.first else { return }
                MessageViewModel.shared.handleFile(url)
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
