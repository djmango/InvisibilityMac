import SwiftUI
import OSLog

struct ChatImageView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatImage")

    let imageItem: ChatDataItem
    let nsImage: NSImage
    
    @State private var isHovering: Bool = false

    init(imageItem: ChatDataItem) {
        self.imageItem = imageItem
        self.nsImage = NSImage(data: imageItem.data) ?? NSImage()
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: isHovering ? 4 : 0)

            Button(action: {
                ChatViewModel.shared.removeItem(id: imageItem.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title)
            }
            .opacity(isHovering ? 1 : 0)
            .buttonStyle(PlainButtonStyle())
            .onHover{ isHovering in
                HoverTrackerModel.shared.targetType = isHovering ? .chatImageDelete : .nil_
                HoverTrackerModel.shared.targetItem = isHovering ? imageItem.id : nil
            }
        }
        .padding(.horizontal, 10)
        .onHover { hovering in
            isHovering = hovering
            HoverTrackerModel.shared.targetType = hovering ? .chatImage : .nil_
            HoverTrackerModel.shared.targetItem = hovering ? imageItem.id : nil
        }
    }
}
