import SwiftUI

struct MemoryView: View {
    @StateObject private var viewModel = MemoryViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                MemoryHeader(title: "My Memories", onSearch: {}, onClose: {})
                MemoryGrid(memories: viewModel.memories)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 10)
        }
        // .frame(width: 400, height: 815, alignment: .top)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            viewModel.fetchMemories()
        }
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
                // .frame(width: 44, height: 44)
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
                // .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 4)
        // .frame(maxWidth: .infinity, alignment: .center)
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
    }
}

struct MemoryCard: View {
    let memory: APIMemory

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color(hex: 0x2E2E3F, alpha: 0.04), radius: 4, x: 2, y: 3)
                .shadow(color: Color(hex: 0x2E2E45, alpha: 0.04), radius: 3, x: 1, y: 2)
                .shadow(color: Color(hex: 0x2A3345, alpha: 0.04), radius: 2, x: 0, y: 1)
                .shadow(color: Color(hex: 0x0E3F7E, alpha: 0.04), radius: 2, x: 0, y: 0)

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
        // .frame(width: 164, height: 231)
        .rotation3DEffect(.degrees(Double.random(in: -5 ... 5)), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(Double.random(in: -2 ... 2)), axis: (x: 0, y: 0, z: 1), perspective: 0.5)
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
