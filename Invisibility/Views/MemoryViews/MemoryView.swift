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

    var groupedMemories: [(String, [APIMemory])] {
        Dictionary(grouping: viewModel.memories, by: { $0.grouping ?? "Ungrouped" })
            .sorted(by: { $0.key < $1.key })
    }

    var body: some View {
        List {
            MemoryHeader(title: "My Memories", onSearch: viewModel.fetchAPISync, onClose: viewModel.closeView, isRefreshing: viewModel.isRefreshing)

            ForEach(groupedMemories, id: \.0) { group, memories in
                DisclosureGroup(
                    content: {
                        ForEach(memories) { memory in
                            // Text(memory.content)
                            MemoryRow(memory: memory)
                        }
                    },
                    label: {
                        HStack {
                            Text(memories.first?.emoji ?? "")
                                .font(.system(size: 16))
                            Text(group)
                                .font(.system(size: 16))
                            Spacer()
                            Text("\(memories.count) memories")
                                .foregroundColor(.secondary)
                        }
                    }
                )
            }
        }
        .listStyle(.inset)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
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

struct MemoryRow: View {
    @State var memory: APIMemory
    @State private var isEditing = false

    var body: some View {
        HStack {
            if isEditing {
                TextField("Memory", text: Binding(
                    get: { memory.content },
                    set: { memory.content = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    isEditing = false
                    // Here you would update the memory in your data source
                }
            } else {
                Text(memory.content)
            }

            Spacer()

            Button(action: { isEditing.toggle() }) {
                Image(systemName: isEditing ? "checkmark" : "pencil")
            }
        }
    }
}
