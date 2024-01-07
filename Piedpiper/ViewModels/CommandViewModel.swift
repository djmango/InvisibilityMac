import Foundation
import OptionalKit

@Observable
final class CommandViewModel: ObservableObject {
    var isAddChatViewPresented: Bool = false
    var isRenameChatViewPresented: Bool = false
    var isDeleteChatConfirmationPresented: Bool = false

    var selectedChat: Chat? = nil

    var chatToRename: Chat? {
        didSet {
            if chatToRename.isNotNil {
                isRenameChatViewPresented = true
            }
        }
    }

    var chatToDelete: Chat? {
        didSet {
            if chatToDelete.isNotNil {
                isDeleteChatConfirmationPresented = true
            }
        }
    }
}
