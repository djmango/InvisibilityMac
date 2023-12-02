import SwiftUI
import ViewState

struct AppView: View {
    @Environment(CommandViewModel.self) private var commandViewModel
    
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
    }
}
