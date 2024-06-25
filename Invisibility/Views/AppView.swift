import OSLog
import Sparkle
import SwiftUI

struct AppView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "AppView")

    @ObservedObject private var toastViewModel = ToastViewModel.shared
    @AppStorage("onboardingViewed") private var onboardingViewed = false

    var body: some View {
        MainView()
            .pasteDestination(for: URL.self) { urls in
                guard let url = urls.first else { return }
                InvisibilityFileManager.handleFile(url)
            }
            .simpleToast(isPresented: $toastViewModel.showToast, options: toastViewModel.toastOptions) {
                HStack {
                    Image(systemName: toastViewModel.icon)
                        .foregroundColor(.yellow)
                    Text(toastViewModel.title)
                        .font(.title3)
                }
                .padding(15)
                .background(.background)
                .cornerRadius(16)
                .padding()
                .shadow(radius: 2)
            }
            .onHover{ _ in
                HoverTrackerModel.shared.targetType = .nil_
            }
    }
}
