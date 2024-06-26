import SwiftUI

struct MessageListItemView: View {
    let message: APIMessage
    //@ObservedObject var branchManagerModel = BranchManagerModel.shared
    @Binding var whoIsHovered: String?
    
    private var isAssistant: Bool {
        message.role == .assistant
    }
    /*
    private var isEditing: Bool {
        guard let editMsg = branchManagerModel.editMsg else {
            return false
        }
        return editMsg.id == message.id
    }
     */
    
    private var isHovered: Bool {
        print("isHoveredChange")
        print(whoIsHovered)
        print(message.id)
        return whoIsHovered == message.id.uuidString
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MessageContentView(message: message)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(nsColor: .separatorColor))
                )
                .background(
                    VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
                )
            
            if isHovered  {
                MessageActionButtonsView(message: message, whoIsHovered: $whoIsHovered)
                    .frame(width: 200)
                    .offset(x: -10, y: 10)
                    .onHover{ hovered in
                        print("in msactionbuttonsview")
                        print(hovered)
                    }
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 3)
        .onChange(of: isHovered) { newval in
            print("isHovered changed:")
            print(newval)
        }
    }
}
