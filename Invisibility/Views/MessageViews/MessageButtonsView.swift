import ViewCondition
import SwiftUI

struct MessageActionButtonsView: View {
    let message: APIMessage
    @State private var isCopied: Bool = false
    @State var whichButtonIsHovered: String? = nil
    
    // use this for hovering
    @Binding var whoIsHovered: String?
    
    @ObservedObject var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared
    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject var branchManagerModel: BranchManagerModel = BranchManagerModel.shared

    init (message: APIMessage, whoIsHovered: Binding<String?>) {
        self.message = message
        self._whoIsHovered = whoIsHovered
    }
    
    private var isHovered: Bool {
        whoIsHovered == message.id.uuidString
    }
    
    private var isBranch: Bool {
        branchManagerModel.isBranch(message: message)
    }
    
    private var canMoveLeft: Bool {
        branchManagerModel.canMoveLeft(message: message)
    }
    
    private var canMoveRight: Bool {
        branchManagerModel.canMoveRight(message: message)
    }
    
    private var isGenerating: Bool {
        messageViewModel.isGenerating && (message.text.isEmpty)
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
    
    private var isCopyButtonVisible: Bool {
        (isHovered || (shortcutViewModel.modifierFlags.contains(.command))) && !isEditing
    }

    private var isRegenerateButtonVisible: Bool {
        ((isHovered && message.role == .assistant) || (shortcutViewModel.modifierFlags.contains(.command))) && !isEditing
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Spacer()
            HStack(spacing: 2) {
                MessageButtonItemView(
                    label: "Edit",
                    icon: "pencil",
                    shortcut_hint: nil,
                    whichButtonIsHovered: $whichButtonIsHovered,
                    action: {editAction()}
                )
                .visible(if: !isEditing && !isAssistant, removeCompletely: true)
                
                MessageButtonItemView(
                    label: "Go Back",
                    icon: canMoveLeft ? "arrowtriangle.backward.fill" : "arrowtriangle.backward",
                    shortcut_hint: nil,
                    whichButtonIsHovered: $whichButtonIsHovered,
                    action: { branchManagerModel.moveLeft(message: message) }
                )
                .visible(if: isBranch, removeCompletely: true)
                
                Text("\(branchManagerModel.getCurrBranchIdx(message: message))/\(branchManagerModel.getTotalBranches(message: message))")
                    .font(.system(size: 8))
                    .foregroundColor(.chatButtonForeground)
                    .visible(if: isBranch, removeCompletely: true)
                
                MessageButtonItemView(
                    label: "Go Forward",
                    icon: canMoveRight ? "arrowtriangle.forward.fill" : "arrowtriangle.forward",
                    shortcut_hint: nil,
                    whichButtonIsHovered: $whichButtonIsHovered,
                    action: { branchManagerModel.moveRight(message: message) }
                )
                .visible(if: isBranch, removeCompletely: true)
                
                MessageButtonItemView(
                    label: "Regenerate",
                    icon: "arrow.clockwise",
                    shortcut_hint: "⌘ ⇧ R",
                    whichButtonIsHovered: $whichButtonIsHovered,
                    action: regenerateAction
                )
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .visible(if: isRegenerateButtonVisible, removeCompletely: true)
                
                MessageButtonItemView(
                    label: "Copy",
                    icon: isCopied ? "checkmark" : "square.on.square",
                    shortcut_hint: "⌘ ⌥ C",
                    whichButtonIsHovered: $whichButtonIsHovered,
                    action: copyAction
                )
                .keyboardShortcut("c", modifiers: [.command, .option])
                .changeEffect(.jump(height: 10), value: isCopied)
                .visible(if: isCopyButtonVisible, removeCompletely: true)
                
                // cancel
                Button(action: {
                    // Add your cancel action here
                    print("clicked cancel")
                    branchManagerModel.clearEdit()
                }) {
                    Text("Cancel")
                        .font(.system(size: 10))
                        .padding(5)
                        .background(whichButtonIsHovered == "Cancel" ? Color.blue.opacity(0.8) : Color.clear)
                        .foregroundColor(whichButtonIsHovered == "Cancel" ? .white : .blue)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    print("hovering over cancel")
                    whichButtonIsHovered = hovering ? "Cancel" : nil
                }
                .visible(if: isEditing, removeCompletely: true)

                // submit
                Button(action: {
                    // Add your submit action here
                    print("clicked submit")
                    Task {
                        await MessageViewModel.shared.sendFromChat(editMode: true)
                    }
                }) {
                    Text("Submit")
                        .font(.system(size: 10))
                        .padding(5)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .visible(if: isEditing, removeCompletely: true)

            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
            .animation(AppConfig.snappy, value: whoIsHovered)
            .animation(AppConfig.snappy, value: shortcutViewModel.modifierFlags)
        }
    }
    
    private func editAction() {
        branchManagerModel.editMsg = message
        branchManagerModel.editText = message.text
    }
    
    private func copyAction() {
       let pasteBoard = NSPasteboard.general
       pasteBoard.clearContents()
       pasteBoard.setString(message.text, forType: .string)
       isCopied = true
       DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
           isCopied = false
       }
    }

    private func regenerateAction() {
        Task {
            await messageViewModel.regenerate(message: message)
        }
    }
}
