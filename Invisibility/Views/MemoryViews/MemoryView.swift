import SwiftUI

struct MemoryView: View {
    @StateObject private var viewModel = MemoryViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                MemoryHeader(title: "My Memories", onSearch: {}, onClose: {})
                MemoryGrid(memories: viewModel.memories)
            }
        }
        .scrollIndicators(.never)
        .defaultScrollAnchor(.bottom)
        .onAppear {
            viewModel.fetchMemories()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }
}

struct MemoryHeader: View {
    let title: String
    let onSearch: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black)
            }
            Spacer()
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .tracking(-0.40)
                .foregroundColor(.black)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 12)
    }
}

struct MemoryGrid: View {
    let memories: [APIMemory]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(memories) { memory in
                MemoryCard(memory: memory)
            }
        }
        .padding(8)
    }
}

struct MemoryCard: View {
    let memory: APIMemory
    @State var isHovering: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(radius: isHovering ? 8 : 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(formatDate(memory.createdAt))
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.15)
                    .foregroundColor(Color(hex: 0x000000, alpha: 0.51))

                Text(memory.emoji)
                    .font(.system(size: 40))

                Text(memory.content)
                    .textStyle(BodyText())

                Spacer()

                HStack {
                    Spacer()
                    Text(timeAgo(memory.createdAt))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color(hex: 0x000000, alpha: 0.5))
                }
            }
            .padding(12)
        }
        .scaleEffect(isHovering ? 1.02 : 1)
        .onHover { hovering in
            withAnimation(AppConfig.snappy) {
                isHovering = hovering
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct BodyText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(Color(hex: 0x000000, alpha: 0.7))
            .multilineTextAlignment(.leading)
            .lineSpacing(4)
            .lineLimit(5)
    }
}

extension Color {
    init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0xFF00) >> 8) / 255.0
        let blue = Double((hex & 0xFF) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension Text {
    func textStyle(_ style: some ViewModifier) -> some View {
        ModifiedContent(content: self, modifier: style)
    }
}
