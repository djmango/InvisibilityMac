import os
import SwiftUI
import ViewState

struct AppView: View {
    @Environment(CommandViewModel.self) private var commandViewModel
    @Environment(OllamaViewModel.self) private var ollamaViewModel
    private let logger = Logger(subsystem: "pro.piedpiper.app", category: "OllamaViewModel")

    var body: some View {
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
    }
}
