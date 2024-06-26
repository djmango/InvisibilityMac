import SwiftUI

struct MessageListItemView: View {
    let message: APIMessage
    @ObservedObject var branchManagerModel = BranchManagerModel.shared
    @Binding var whoIsHovered: String?
    
    init (message: APIMessage, whoIsHovered : Binding<String?>) {
        self.message = message
        self._whoIsHovered = whoIsHovered
    }

    private var isAssistant: Bool {
        message.role == .assistant
    }
    
    private var isEditing: Bool {
        guard let editMsg = branchManagerModel.editMsg else {
            return false
        }
        return editMsg.id == message.id
    }
    
    private var isHovered: Bool {
        whoIsHovered == message.id.uuidString
    }
    
    var body: some View {
        MessageContentView(message: message)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(nsColor: .separatorColor))
            )
            .background(
                VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
            )
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 3)
            .overlay(
                MessageActionButtonsView(message: message, whoIsHovered: $whoIsHovered)
                 .offset(y: 10)
                 .offset(x: 130)
                 .frame(width: 200)
                 .visible(if: isHovered || isEditing)
                 .onHover{ hovered in
                     print("hovered")
                 }
            )
    }
}
