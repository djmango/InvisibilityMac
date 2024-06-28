import OSLog
import SwiftUI



struct ChatImageView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatImage")

    let imageItem: ChatDataItem
    let nsImage: NSImage

    @State private var isHovering: Bool = false

    private var chatFieldViewModel: ChatFieldViewModel = ChatFieldViewModel.shared

    init(imageItem: ChatDataItem) {
        self.imageItem = imageItem
        self.nsImage = NSImage(data: imageItem.data) ?? NSImage()
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: isHovering ? 4 : 0)
                .onHover { hovering in
                    isHovering = hovering
                }

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
            .visible(if: isHovering)
        }
        .padding(.horizontal, 10)
    
    }
}
