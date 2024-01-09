import Foundation

@Observable
final class CommandViewModel: ObservableObject {
    var isAddChatViewPresented: Bool = false
    var isRenameChatViewPresented: Bool = false
    var isDeleteChatConfirmationPresented: Bool = false

    var selectedChat: Chat? = nil

    var chatToRename: Chat? {
        didSet {
            if chatToRename != nil {
                isRenameChatViewPresented = true
            }
        }
    }

    var chatToDelete: Chat? {
        didSet {
            if chatToDelete != nil {
                isDeleteChatConfirmationPresented = true
            }
        }
    }
}
