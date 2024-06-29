import OSLog
import SwiftUI



struct ChatImageView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatImage")

    let imageItem: ChatDataItem
    let itemWidth: CGFloat
    let itemSpacing: CGFloat
    let nsImage: NSImage
    @Binding var whoIsHovering: UUID?
    @State private var isHovering = false

    private var chatFieldViewModel: ChatFieldViewModel = ChatFieldViewModel.shared

    init(imageItem: ChatDataItem, itemSpacing: CGFloat, itemWidth: CGFloat, whoIsHovering: Binding<UUID?>) {
        self.imageItem = imageItem
        self.nsImage = NSImage(data: imageItem.data) ?? NSImage()
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        self._whoIsHovering = whoIsHovering
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
            .onHover { hovering in
                HoverTrackerModel.shared.targetType = hovering ? .chatImageDelete : .nil_
                HoverTrackerModel.shared.targetItem = hovering ? imageItem.id.uuidString : nil
            }
            .padding(3)
            .focusable(false)
            .visible(if: isHovering, removeCompletely: true)
        }
        .padding(.horizontal, itemSpacing)
        .onChange(of: whoIsHovering) {
            isHovering = $0 == imageItem.id
        }
    }
}
