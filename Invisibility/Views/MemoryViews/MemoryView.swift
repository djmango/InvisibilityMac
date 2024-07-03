import SwiftUI

struct MemoryView: View {
    @StateObject private var viewModel = MemoryViewModel()
    // NOTE: Search is refresh for now

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                MemoryHeader(title: "My Memories", onSearch: viewModel.fetchAPISync, onClose: viewModel.closeView)
                MemoryGrid(memories: viewModel.memories)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 25)
        }
        .scrollIndicators(.never)
        .defaultScrollAnchor(.top)
        .onAppear { viewModel.fetchAPISync() }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .background(
            Rectangle()
                .fill(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .padding(15)
    }
}

struct MemoryHeader: View {
    let title: String
    let onSearch: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSearch) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)

            Spacer()
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .tracking(-0.40)
                .foregroundColor(.primary)

            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .padding(.horizontal, 4)
    }
}

struct MemoryGrid: View {
    let memories: [APIMemory]

    private let minWidth: CGFloat = 150
    private let maxWidth: CGFloat = 350
    private let spacing: CGFloat = 16

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: minWidth, maximum: maxWidth), spacing: spacing)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(memories) { memory in
                MemoryCard(memory: memory)
            }
        }
        .padding(.horizontal, spacing)
    }
}

struct MemoryCard: View {
    let memory: APIMemory
    @State var isHovering: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.cardBackground)
                .shadow(radius: isHovering ? 8 : 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(formatDate(memory.created_at))
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.15)
                    .foregroundColor(.secondary)

                // Text(timeAgo(memory.created_at))
                //     .font(.system(size: 12, weight: .medium))
                //     .tracking(0.15)
                //     .foregroundColor(.secondary)

                Text(memory.emoji ?? "")
                    .font(.system(size: 40))

                Text(memory.content)
                    .font(.system(size: 14, weight: .regular))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .lineLimit(5)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Spacer()
                    Text(memory.grouping ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.history)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.history.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                    Spacer()
                }
            }
            .padding(12)
        }
        .scaleEffect(isHovering ? 1.02 : 1)
        .whenHovered { hovering in
            withAnimation(AppConfig.snappy) {
                isHovering = hovering
            }
        }
    }
}
