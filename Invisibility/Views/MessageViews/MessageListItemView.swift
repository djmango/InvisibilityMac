import SwiftUI

struct MessageListItemView: View {
    let message: APIMessage

    @State private var isHovered: Bool = false
    @State private var isMsgHovered: Bool = false
    @ObservedObject var branchManagerModel = BranchManagerModel.shared
    
    private var isBranch: Bool {
        let ret = branchManagerModel.isBranch(message: message)
        print("isBranch: \(ret)")
        return ret
    }

    private var isEditing: Bool {
        guard let editMsg = branchManagerModel.editMsg else {
            return false
        }
        return editMsg.id == message.id
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                MessageContentView(message: message)
                    .onHover { hovered in
                        isHovered = hovered
                        isMsgHovered = hovered
                        if isBranch {
                            print(isMsgHovered )
                        }
                    }
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
                   
                
                // Spacer to push the content to the top
                Spacer().frame(height: 15)
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 3)
    }
}

struct EditButtonsView: View {
    let message: APIMessage
    @ObservedObject var branchManagerModel = BranchManagerModel.shared
    @State private var leftArrowHovered = false
    @State private var rightArrowHovered = false
    
    private var canMoveLeft: Bool {
        BranchManagerModel.shared.canMoveLeft(message: message)
    }
    
    private var canMoveRight: Bool {
        BranchManagerModel.shared.canMoveRight(message: message)
    }

    var body: some View {
        HStack {
            Image(systemName: "pencil")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 10, height: 10)
                .foregroundColor(.chatButtonForeground)
                .onTapGesture {
                    editAction()
                }
                .onHover {hovered in
                    NSCursor.pointingHand.set()
                }
            
                Image(systemName: leftArrowHovered && canMoveLeft ? "arrowtriangle.backward.fill" : "arrowtriangle.backward")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundColor(.chatButtonForeground)
                    .onTapGesture {
                        branchManagerModel.moveLeft(message: message)
                    }
                    .onHover{ hovered in
                        leftArrowHovered = hovered
                        NSCursor.pointingHand.set()
                    }
                
                Image(systemName: rightArrowHovered && canMoveRight ? "arrowtriangle.forward.fill" : "arrowtriangle.forward")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundColor(.chatButtonForeground)
                    .onTapGesture {
                        branchManagerModel.moveRight(message: message)
                    }
                    .onHover { hovered in
                        rightArrowHovered = hovered
                        NSCursor.pointingHand.set()
                    }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.5))
            .cornerRadius(10)
        }
    private func editAction() {
        print("editAction()")
        BranchManagerModel.shared.editMsg = message
        BranchManagerModel.shared.editText = message.text
    }

}
