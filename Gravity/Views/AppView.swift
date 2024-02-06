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
                NavigationSplitView {
                    ChatSidebarListView()
                        .navigationSplitViewColumnWidth(min: 240, ideal: 240)
                } detail: {
                    MessageView(for: CommandViewModel.shared.selectedChat)
                }
                .toolbar {
                    ToolbarView()
                }
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
