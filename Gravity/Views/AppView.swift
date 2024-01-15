import os
import SwiftUI
import ViewState

struct AppView: View {
    @EnvironmentObject private var imageViewModel: ImageViewModel
    private let logger = Logger(subsystem: "ai.grav.app", category: "AppView")

    @AppStorage("onboardingViewed") private var onboardingViewed = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if onboardingViewed {
                    NavigationSplitView {
                        ChatSidebarListView()
                            .navigationSplitViewColumnWidth(min: 240, ideal: 240)
                    } detail: {
                        if let selectedChat = CommandViewModel.shared.selectedChat {
                            MessageView(for: selectedChat)
                        } else {
                            ContentUnavailableView {
                                Text("No Chat Selected")
                            }
                        }
                    }

                    if let (image, frame) = imageViewModel.getImage() {
                        ExpandedImageView(nsImage: image, originalFrame: frame, geometry: geometry, onDismiss: {
                            imageViewModel.clearImage()
                        })
                    }
                } else {
                    OnboardingView()
                }
            }
        }
    }
}
