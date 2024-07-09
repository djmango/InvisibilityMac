import SwiftUI

import SwiftUI

struct MemoryHeader: View {
    let title: String
    let onSearch: () -> Void
    let onClose: () -> Void
    var isRefreshing: Bool

    var body: some View {
        HStack {
            Button(action: onSearch) {
                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)

            Spacer()
            Text(title)
                .font(.system(size: 24, weight: .bold))
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

struct MemoryView: View {
    @StateObject private var viewModel = MemoryViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                MemoryHeader(title: "My Memories", onSearch: viewModel.fetchAPISync, onClose: viewModel.closeView, isRefreshing: viewModel.isRefreshing)
                MemoryGrid(memory_groups: viewModel.memory_groups, memories: viewModel.memories)
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

struct MemoryGroupCard: View {
    let memoryGroup: APIMemoryGroup
    let latestMemory: APIMemory?
    @Binding var expandedGroups: Set<UUID>
    let childCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.windowBackground)
                .shadow(radius: isExpanded ? 6 : 1)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(memoryGroup.emoji) \(memoryGroup.name)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    ExpandButton(isExpanded: isExpanded, count: childCount)
                }

                if let latestMemory {
                    Text(latestMemory.content)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }

                Spacer()

                Text(formatDate(memoryGroup.updated_at))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .onTapGesture {
            withAnimation(AppConfig.snappy) {
                toggleExpansion()
            }
        }
    }

    private var isExpanded: Bool {
        expandedGroups.contains(memoryGroup.id)
    }

    private func toggleExpansion() {
        if isExpanded {
            expandedGroups.remove(memoryGroup.id)
        } else {
            expandedGroups.insert(memoryGroup.id)
        }
    }
}

struct ExpandButton: View {
    let isExpanded: Bool
    let count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)

            if isExpanded {
                Image(systemName: "minus")
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            } else {
                Group {
                    Text("\(count)")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .bold))

                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .bold))
                        .offset(x: 5, y: -5)
                }
            }
        }
    }
}

struct MemoryCard: View {
    let memory: APIMemory
    @State private var isHovering: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.windowBackground)
                .shadow(radius: isHovering ? 6 : 1)

            VStack(alignment: .leading, spacing: 8) {
                Text(memory.content)
                    .font(.system(size: 14, weight: .regular))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .lineLimit(5)
                    .foregroundColor(.primary)

                Spacer()

                Text(formatDate(memory.updated_at))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
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

struct MemoryGrid: View {
    @State private var expandedGroups: Set<UUID> = []
    let memory_groups: [APIMemoryGroup]
    let memories: [APIMemory]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 16) {
            ForEach(memory_groups, id: \.id) { group in
                MemoryGroupCard(
                    memoryGroup: group,
                    latestMemory: memories.first(where: { $0.group_id == group.id }),
                    expandedGroups: $expandedGroups,
                    childCount: memories.filter { $0.group_id == group.id }.count
                )

                if expandedGroups.contains(group.id) {
                    ForEach(memories.filter { $0.group_id == group.id }, id: \.id) { memory in
                        MemoryCard(memory: memory)
                    }
                }
            }

            ForEach(memories.filter { $0.group_id == nil }, id: \.id) { memory in
                MemoryCard(memory: memory)
            }
        }
        .padding()
    }
}
