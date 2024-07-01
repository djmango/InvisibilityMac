import SwiftUI

struct MessageListItemView: View {
    let message: APIMessage

    @State private var isHovered: Bool = false

    var body: some View {
        MessageContentView(message: message)
            .whenHovered { hovering in
                withAnimation(AppConfig.snappy) {
                    isHovered = hovering
                }
                // if hovering {
                //     isHovered = true
                // } else {
                //     withAnimation(AppConfig.snappy) {
                //         isHovered = false
                //     }
                // }
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
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 3)
    }
}
