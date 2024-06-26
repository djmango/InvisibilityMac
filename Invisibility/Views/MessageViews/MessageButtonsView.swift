import ViewCondition
import SwiftUI

struct MessageActionButtonsView: View {
    let message: APIMessage
    @Binding private var isHovered: Bool
    @State private var isCopied: Bool = false
    @State private var whoIsHovering: String?
    
    @ObservedObject var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared
    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject var branchManagerModel: BranchManagerModel = BranchManagerModel.shared

    init (message: APIMessage, isHovered: Binding<Bool>) {
        self.message = message
        self._isHovered = isHovered
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
    
    private var isEditing: Bool {
        guard let editMsg = branchManagerModel.editMsg else {
            return false
        }
        return editMsg.id == message.id
    }
    
    private var isCopyButtonVisible: Bool {
        isHovered || (shortcutViewModel.modifierFlags.contains(.command)) && !isEditing
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
                    whoIsHovering: $whoIsHovering,
                    action: editAction
                )
                .visible(if: !isEditing, removeCompletely: true)
                
                MessageButtonItemView(
                    label: nil,
                    icon: canMoveLeft ? "arrowtriangle.backward.fill" : "arrowtriangle.backward",
                    shortcut_hint: nil,
                    whoIsHovering: $whoIsHovering,
                    action: { branchManagerModel.moveLeft(message: message) }
                )
                .visible(if: isBranch, removeCompletely: true)
                
                Text("\(branchManagerModel.getCurrBranchIdx(message: message))/\(branchManagerModel.getTotalBranches(message: message))")
                    .font(.system(size: 8))
                    .foregroundColor(.chatButtonForeground)
                    .visible(if: isBranch, removeCompletely: true)
                
                MessageButtonItemView(
                    label: nil,
                    icon: canMoveRight ? "arrowtriangle.forward.fill" : "arrowtriangle.forward",
                    shortcut_hint: nil,
                    whoIsHovering: $whoIsHovering,
                    action: { branchManagerModel.moveRight(message: message) }
                )
                .visible(if: isBranch, removeCompletely: true)
                
                MessageButtonItemView(
                    label: "Regenerate",
                    icon: "arrow.clockwise",
                    shortcut_hint: "⌘ ⇧ R",
                    whoIsHovering: $whoIsHovering,
                    action: regenerateAction
                )
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .visible(if: isRegenerateButtonVisible, removeCompletely: true)
                
                MessageButtonItemView(
                    label: "Copy",
                    icon: isCopied ? "checkmark" : "square.on.square",
                    shortcut_hint: "⌘ ⌥ C",
                    whoIsHovering: $whoIsHovering,
                    action: copyAction
                )
                .keyboardShortcut("c", modifiers: [.command, .option])
                .changeEffect(.jump(height: 10), value: isCopied)
                .visible(if: isCopyButtonVisible, removeCompletely: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
            .animation(AppConfig.snappy, value: whoIsHovering)
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
