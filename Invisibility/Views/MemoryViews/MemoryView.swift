import SwiftUI

import SwiftUI

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
        .background(Rectangle().fill(Color.white.opacity(0.001)))
    }
}

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
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .shadow(color: Color.black.opacity(0.7), radius: 2)
            .frame(width: 24, height: 24)

            Spacer()
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.7), radius: 2)

            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .shadow(color: Color.black.opacity(0.7), radius: 2)
        }
        .padding(14)
        .padding(.horizontal, 4)
    }
}

struct MemoryGroupCard: View {
    let memoryGroup: APIMemoryGroup
    let latestMemory: APIMemory?
    @Binding var expandedGroups: Set<UUID>
    let childCount: Int
    @State private var isHovering: Bool = false

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
                Text("\(memoryGroup.emoji)")
                    .font(.title2)
                    .shadow(radius: 1)

                Text("\(memoryGroup.name)")
                    .font(.title3)
                    .bold()
                    .padding(.top, 2)

                if let latestMemory {
                    Text(latestMemory.content)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                Spacer()
            }
            Spacer()
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ExpandButton(isExpanded: isExpanded, count: childCount)
                        .visible(if: isHovering || isExpanded)
                        .shadow(radius: 1)
                }
            }
        )
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
                .shadow(radius: isHovering ? 3 : 0)
        )
        .scaleEffect(isHovering ? 1.02 : 1)
        .onTapGesture {
            withAnimation(AppConfig.snappy) {
                toggleExpansion()
            }
        }
        .whenHovered { hovering in
            withAnimation(AppConfig.snappy) {
                isHovering = hovering
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
                    Text("+\(count)")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .bold))
                }
            }
        }
    }
}

struct MemoryCard: View {
    let memory: APIMemory
    let memory_group: APIMemoryGroup?
    @State private var isHovering: Bool = false

    var body: some View {
        VStack(alignment: .center) {
            if let memory_group {
                Text("\(memory_group.emoji) \(memory_group.name)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(memory.content)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .lineLimit(5)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
                .shadow(radius: isHovering ? 3 : 0)
        )
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

    var memory_groups_with_memories: [APIMemoryGroup] {
        memory_groups.filter { group in
            memories.contains(where: { $0.group_id == group.id })
        }
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 350))], spacing: 16) {
            ForEach(memory_groups_with_memories, id: \.id) { group in
                MemoryGroupCard(
                    memoryGroup: group,
                    latestMemory: memories.first(where: { $0.group_id == group.id }),
                    expandedGroups: $expandedGroups,
                    childCount: memories.filter { $0.group_id == group.id }.count
                )
                .frame(height: 170)

                if expandedGroups.contains(group.id) {
                    ForEach(memories.filter { $0.group_id == group.id }, id: \.id) { memory in
                        MemoryCard(memory: memory, memory_group: group)
                            .frame(height: 170)
                    }
                }
            }

            ForEach(memories.filter { $0.group_id == nil }, id: \.id) { memory in
                MemoryCard(memory: memory, memory_group: nil)
                    .frame(height: 170)
            }
        }
    }
}
