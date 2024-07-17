import SwiftUI

struct MessageListItemView: View {
    let message: APIMessage

    @State private var isHovered: Bool = false

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
            .padding(.bottom, 13)
            .contentShape(Rectangle()) // This ensures the entire area is tappable
            .whenHovered { hovering in
                withAnimation(AppConfig.snappy) {
                    isHovered = hovering
                }
            }
    }
}
