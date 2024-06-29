import SwiftUI

struct ChatPDFView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatPDF")

    let item: ChatDataItem
    let itemSpacing: CGFloat
    let itemWidth: CGFloat
    @Binding var whoIsHovering: UUID?
    @State private var isHovering = false

    private var chatFieldViewModel: ChatFieldViewModel = ChatFieldViewModel.shared

    init(pdfItem: ChatDataItem, itemSpacing: CGFloat, itemWidth: CGFloat, whoIsHovering: Binding<UUID?>) {
        self.item = pdfItem
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        self._whoIsHovering = whoIsHovering
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image("PDFIcon") // Ensure this image is included in your assets
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: itemWidth, height: itemWidth)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: isHovering ? 4 : 0)

            Button(action: {
                chatFieldViewModel.removeItem(id: item.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray) // Make the button red to highlight it as a delete button
                    .font(.title) // Adjust the font size as needed
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                HoverTrackerModel.shared.targetType = isHovering ? .chatPDFDelete : .nil_
                HoverTrackerModel.shared.targetItem = isHovering ? item.id.uuidString : nil
            }
            .padding(3)
            .focusable(false)
            .visible(if: isHovering, removeCompletely: true)
        }
        .padding(.horizontal, itemSpacing)
        .onChange(of: whoIsHovering) {
            isHovering = $0 == item.id
        }
    }
}
