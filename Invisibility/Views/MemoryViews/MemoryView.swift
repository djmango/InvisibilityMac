import SwiftUI

import SwiftUI

struct MemoryHeader: View {
    let title: String
    let onSearch: () -> Void
    let onClose: () -> Void
    var isRefreshing: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSearch) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.primary)

                ProgressView()
                    .visible(if: isRefreshing)
            }
            .buttonStyle(.plain)

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
                MemoryGroupList(memories: viewModel.memories)
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

struct MemoryGroupList: View {
    let memories: [APIMemory]
    @State private var expandedGroups: Set<String> = []

    var groupedMemories: [String: [APIMemory]] {
        Dictionary(grouping: memories, by: { $0.grouping ?? "Ungrouped" })
    }

    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(groupedMemories.keys.sorted(), id: \.self) { group in
                MemoryGroupCard(
                    group: group,
                    emoji: groupedMemories[group]?.first?.emoji ?? "",
                    memories: groupedMemories[group] ?? [],
                    isExpanded: expandedGroups.contains(group),
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedGroups.contains(group) {
                                expandedGroups.remove(group)
                            } else {
                                expandedGroups.insert(group)
                            }
                        }
                    }
                )
            }
        }
    }
}

struct MemoryGroupCard: View {
    let group: String
    let emoji: String
    let memories: [APIMemory]
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(emoji)
                        .font(.system(size: 40))
                    Text(group)
                        .font(.title2.bold())
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(.plain)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)

            if isExpanded {
                MemoryContentGrid(memories: memories)
                    .padding(.top, 8)
            }
        }
        .onTapGesture(perform: onTap)
    }
}

struct MemoryContentGrid: View {
    let memories: [APIMemory]
    let columns = [GridItem(.adaptive(minimum: 150, maximum: 300), spacing: 16)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(memories) { memory in
                MemoryCard(memory: memory)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct MemoryCard: View {
    @State var memory: APIMemory
    @State var isEditing = false
    @State private var isHovering = false
    @State private var isNameHovered: Bool = false
    // @FocusState private var isFocused: Bool

    var body: some View {
        // VStack(alignment: .leading, spacing: 8) {
        //     if isEditing {
        //         TextField("Memory", text: Binding(
        //             get: { memory.content },
        //             set: { memory.content = $0 }
        //         ))
        //         .textFieldStyle(RoundedBorderTextFieldStyle())
        //         .onSubmit {
        //             isEditing = false
        //             // Update memory in data source
        //         }
        //     } else {
        //         Text(memory.content)
        //             .lineLimit(3)
        //             .font(.body)
        //     }

        //     HStack {
        //         Button(action: { isEditing.toggle() }) {
        //             Image(systemName: isEditing ? "checkmark" : "pencil")
        //         }
        //         .buttonStyle(.plain)
        //         Spacer()
        //         Button(action: {
        //             // Implement delete functionality
        //         }) {
        //             Image(systemName: "trash")
        //         }
        //     }
        // }
        // .padding()
        // .background(Color.white)
        // .cornerRadius(8)
        // .shadow(radius: 2)

        HStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(.history)
                .frame(width: 5)
                .padding(.trailing, 5)

            VStack(alignment: .leading) {
                HStack {
                    if isEditing {
                        TextField("Memory", text: Binding(
                            get: { memory.content },
                            set: { memory.content = $0 }
                        ))
                        // onCommit: viewModel.commitEdit)
                        .font(.title3)
                        .textFieldStyle(.plain)
                        // .focused($isFocused)
                        // .onAppear { isFocused = true }
                    } else {
                        HStack {
                            Text(memory.content)
                                .font(.title3)

                            Image(systemName: "pencil")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.chatButtonForeground)
                                .visible(if: isNameHovered)
                        }
                        .onHover { isNameHovered = $0 }
                        .onTapGesture {
                            isEditing.toggle()
                        }
                    }

                    Spacer()

                    Text(timeAgo(memory.updated_at))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .frame(height: 60)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
                .shadow(radius: 2)
        )
        .overlay(
            VStack {
                HStack {
                    Button(action: {
                        // viewModel.deleteChat
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .padding(5)
                            .foregroundColor(.chatButtonForeground)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                            .background(
                                Circle()
                                    .fill(Color.cardBackground)
                                    .shadow(radius: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(width: 21, height: 21)
                    .padding(.leading, -5)
                    .padding(.top, -5)

                    Spacer()
                }
                Spacer()
            }
            .visible(if: isHovering)
        )
        .whenHovered { hovering in
            withAnimation(AppConfig.snappy) {
                isHovering = hovering
            }
        }
    }
}
