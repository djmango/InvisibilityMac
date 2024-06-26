import SwiftUI

struct MessageListItemView: View {
    let message: APIMessage

    @State private var isHovered: Bool = false
    @ObservedObject var branchManagerModel = BranchManagerModel.shared
    
    private var isAssistant: Bool {
        message.role == .assistant
    }
    
    private var isEditing: Bool {
        guard let editMsg = branchManagerModel.editMsg else {
            return false
        }
        return editMsg.id == message.id
    }
    
    private var showEditButtons:Bool {
        let ret = !isEditing && isHovered && !isAssistant
        return ret
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
            .overlay(
                MessageActionButtonsView(
                    message: message,
                    isHovered: $isHovered
                )
            )
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 3)
            .onHover {
                if $0 {
                    isHovered = true
                } else {
                    withAnimation(AppConfig.snappy) {
                        isHovered = false
                    }
                }
            }
            .overlay(
                MessageActionButtonsView(message: message, isHovered: $isHovered)
                 .offset(y: 10)
                 .offset(x: 130)
                 .frame(width: 200)
                 .visible(if: showEditButtons, removeCompletely: true)
            )
    }
}
