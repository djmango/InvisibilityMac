import OSLog
import SwiftUI

struct ChatImageView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatImage")

    let imageItem: ChatDataItem
    let itemWidth: CGFloat
    let itemSpacing: CGFloat
    let nsImage: NSImage
    @State private var isHovering = false

    private var chatFieldViewModel: ChatFieldViewModel = ChatFieldViewModel.shared

    init(imageItem: ChatDataItem, itemSpacing: CGFloat, itemWidth: CGFloat) {
        self.imageItem = imageItem
        self.nsImage = NSImage(data: imageItem.data) ?? NSImage()
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: itemWidth, height: itemWidth)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: isHovering ? 4 : 0)

            Button(action: {
                chatFieldViewModel.removeItem(id: imageItem.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title)
            }
            .buttonStyle(.plain)
            .padding(3)
            .focusable(false)
            .visible(if: isHovering, removeCompletely: true)
        }
        .whenHovered { hovering in
            withAnimation(AppConfig.snappy) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            chatFieldViewModel.removeItem(id: imageItem.id)
        }
        .padding(.horizontal, itemSpacing)
    }
}
