import SwiftUI

struct MessageListItemView: View {
    private let message: Message

    init(message: Message) {
        self.message = message
    }

    @State private var isHovered: Bool = false

    var body: some View {
        // let _ = Self._printChanges()
        ZStack {
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)

            MessageContentView(message: message)
        }
        .onHover {
            if $0 {
                isHovered = true
            } else {
                isHovered = false
            }
        }
        .overlay(
            MessageActionButtonsView(
                message: message,
                isHovered: $isHovered
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 3)
    }
}
