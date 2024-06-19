import SwiftUI

struct ChatPDFView: View {
    let item: ChatDataItem
    @Binding var whoIsHovering: UUID?

    var isHovering: Bool {
        whoIsHovering == item.id
    }

    init(pdfItem: ChatDataItem, whoIsHovering: Binding<UUID?>) {
        self.item = pdfItem
        self._whoIsHovering = whoIsHovering
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image("PDFIcon")  // Ensure this image is included in your assets
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .shadow(radius: isHovering ? 4 : 0)
                .padding(.horizontal, 10)
            
            Button(action: {
                // This is where the deletion of the PDF item happens
                ChatViewModel.shared.removeItem(id: item.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)  // Make the button red to highlight it as a delete button
                    .font(.title)  // Adjust the font size as needed
                    .opacity(isHovering ? 1 : 0)  // Button is only visible when hovering
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.all, 5)
        }
        .onHover { hovering in
            if hovering {
                whoIsHovering = item.id
            } else {
                if whoIsHovering == item.id {
                    whoIsHovering = nil
                }
            }
        }
        .animation(.easeIn(duration: 0.2), value: ChatViewModel.shared.items)
    }
}
