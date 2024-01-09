import os
import SwiftUI
import SwiftUIImageViewer
import ViewState

struct AppView: View {
    @Environment(CommandViewModel.self) private var commandViewModel
    @Environment(OllamaViewModel.self) private var ollamaViewModel
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
                .environmentObject(ollamaViewModel)

                if let (image, frame) = imageViewModel.getImage() {
                    ExpandedImageView(nsImage: image, originalFrame: frame, geometry: geometry, onDismiss: {
                        imageViewModel.clearImage()
                    })
                }
            }
        }
    }
}
