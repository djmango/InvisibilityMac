import os
import SwiftUI
import ViewState

struct AppView: View {
    @Environment(CommandViewModel.self) private var commandViewModel
    @EnvironmentObject private var imageViewModel: ImageViewModel
    private let logger = Logger(subsystem: "ai.grav.app", category: "OllamaViewModel")

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationSplitView {
                    ChatSidebarListView()
                        .navigationSplitViewColumnWidth(min: 240, ideal: 240)
                } detail: {
                    if let selectedChat = commandViewModel.selectedChat {
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
            }
        }
    }
}
