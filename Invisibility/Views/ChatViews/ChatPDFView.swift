import SwiftUI

struct ChatPDFView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatImage")

    let item: ChatDataItem

    @State private var isHovering: Bool = false

    private var chatFieldViewModel: ChatFieldViewModel = ChatFieldViewModel.shared

    init(pdfItem: ChatDataItem) {
        self.item = pdfItem
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image("PDFIcon") // Ensure this image is included in your assets
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: isHovering ? 4 : 0)

            Button(action: {
                chatFieldViewModel.removeItem(id: item.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray) // Make the button red to highlight it as a delete button
                    .font(.title) // Adjust the font size as needed
            }
            .opacity(isHovering ? 1 : 0) // Button is only visible when hovering
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                HoverTrackerModel.shared.targetType = isHovering ? .chatPDFDelete : .nil_
                HoverTrackerModel.shared.targetItem = isHovering ? item.id.uuidString : nil
            }
        }
        .onHover { hovering in
            isHovering = hovering
            HoverTrackerModel.shared.targetType = hovering ? .chatPDF : .nil_
            HoverTrackerModel.shared.targetItem = hovering ? item.id.uuidString : nil
        }
    }
}
