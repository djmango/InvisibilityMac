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
                ForEach(groupedMemories, id: \.0) { group, memories in
                    ExpandableMemoryGroup(groupName: group, emoji: memories.first?.emoji ?? "", date: memories.first?.updated_at ?? Date(), memories: memories)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 25)
        }
        // .scrollIndicators(.never)
        // .defaultScrollAnchor(.top)
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

    var groupedMemories: [(String, [APIMemory])] {
        Dictionary(grouping: viewModel.memories, by: { $0.grouping ?? "Ungrouped" })
            .sorted(by: { $0.key < $1.key })
    }
}

struct ExpandableMemoryGroup: View {
    let groupName: String
    let emoji: String
    let date: Date
    @State var memories: [APIMemory]
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(emoji).font(.system(size: 40))
                VStack(alignment: .leading) {
                    Text(groupName).font(.headline)
                    Text(formatDate(date)).font(.subheadline)
                }
                Spacer()
                ExpandButton(isExpanded: $isExpanded)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            // .clipShape(RoundedRectangle(cornerRadius: 16))

            if isExpanded {
                ForEach($memories) { $memory in
                    MemoryCardSimplified(memory: $memory, onDelete: { deleteMemory(memory) })
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.spring(), value: isExpanded)
    }

    private func deleteMemory(_ memory: APIMemory) {
        withAnimation {
            memories.removeAll { $0.id == memory.id }
        }
        // Here you would also call your API to delete the memory from the backend
    }
}

struct ExpandButton: View {
    @Binding var isExpanded: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 30, height: 30)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Circle())
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MemoryCardSimplified: View {
    @Binding var memory: APIMemory
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editedContent: String = ""

    var body: some View {
        HStack {
            if isEditing {
                TextField("Memory", text: $editedContent, onCommit: {
                    memory.content = editedContent
                    isEditing = false
                    // Here you would also call your API to update the memory on the backend
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(memory.content)
                    .lineLimit(3)
            }

            Spacer()

            HStack {
                Button(action: {
                    isEditing.toggle()
                    if isEditing {
                        editedContent = memory.content
                    }
                }) {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .frame(height: 60) // Fixed height for uniformity
        .background(Color.secondary.opacity(0.05))
        // .cornerRadius(8)
    }
}
