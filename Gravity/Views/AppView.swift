import OSLog
import SwiftUI
import ViewState

struct AppView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "AppView")

    @ObservedObject private var alertViewModel = AlertManager.shared

    @AppStorage("onboardingViewed") private var onboardingViewed = false

    var body: some View {
        ZStack {
            if onboardingViewed {
                MessageView(for: CommandViewModel.shared.selectedChat)
                    .padding(.top, 120)
            } else {
                OnboardingView()
            }
        }
        .alert(isPresented: $alertViewModel.showAlert) {
            Alert(
                title: Text(alertViewModel.alertTitle),
                message: Text(alertViewModel.alertMessage),
                dismissButton: .default(Text(alertViewModel.alertDismissText))
            )
        }
    }
}
