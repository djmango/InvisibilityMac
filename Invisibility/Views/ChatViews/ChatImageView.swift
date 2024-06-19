import SwiftUI
import OSLog

struct ChatImageView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatImage")

    let imageItem: ChatDataItem
    let nsImage: NSImage
    @Binding var whoIsHovering: UUID?

    var isHovering: Bool {
        whoIsHovering == imageItem.id
    }

    init(imageItem: ChatDataItem, whoIsHovering: Binding<UUID?>) {
        self.imageItem = imageItem
        self.nsImage = NSImage(data: imageItem.data) ?? NSImage()
        self._whoIsHovering = whoIsHovering
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
                // TODO: this raises Error at TUINSRemoteViewController which I need to view and debug. bug only happens when first calling this method upon app launch
                DispatchQueue.main.async{
                    ChatViewModel.shared.removeItem(id: imageItem.id)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)  // You can change to red or any other color
                    .font(.title)  // Adjust the size as needed
            }
            .opacity(isHovering ? 1 : 0)  // Only show the button when hovering
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 10)
        .onHover { hovering in
            if hovering {
                whoIsHovering = imageItem.id
            } else {
                if whoIsHovering == imageItem.id {
                    whoIsHovering = nil
                }
            }
        }
    }
}
