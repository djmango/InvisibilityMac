import SwiftUI

struct MemoryView: View {
    @StateObject private var viewModel = MemoryViewModel()
    @State private var expandedGroup: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                MemoryHeader(title: "My Memories", onRefresh: viewModel.fetchAPISync, onClose: viewModel.closeView, isRefreshing: viewModel.isRefreshing)
                MemoryGrid(memories: viewModel.memories, expandedGroup: $expandedGroup)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background.secondary)
        )
        .overlay(
            Group {
                if expandedGroup != nil {
                    ExpandedGridView(
                        group: expandedGroup!,
                        memories: viewModel.memories.filter { $0.grouping?.rawValue == expandedGroup },
                        expandedGroup: $expandedGroup
                    )
                    .transition(.blurReplace)
                }
            }
        )
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .onAppear { viewModel.fetchAPISync() }
    }
}

struct MemoryHeader: View {
    let title: String
    let onRefresh: () -> Void
    let onClose: () -> Void
    var isRefreshing: Bool

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .regular))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.title2)
                .bold()

            Spacer()

            Button(action: onRefresh) {
                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .regular))
                }
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)
        }
        .padding(14)
        .padding(.horizontal, 4)
    }
}

struct MemoryLeaderCard: View {
    let memory: APIMemory
    let onTap: () -> Void
    @State private var isHovering: Bool = false

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
                Image(systemName: memory.grouping?.sfSymbol ?? "questionmark.circle")
                    .font(.title2)

                Text("\(memory.grouping?.rawValue ?? "Unknown")")
                    .font(.title3)
                    .bold()
                    .padding(.top, 2)

                Text(memory.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                Spacer()
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background.tertiary)
                .shadow(radius: isHovering ? 3 : 0)
        )
        .scaleEffect(isHovering ? 1.02 : 1)
        .whenHovered { hovering in
            withAnimation(AppConfig.snappy) {
                isHovering = hovering
            }
        }
        .onTapGesture(perform: onTap)
    }
}

struct MemoryCard: View {
    @State var memory: APIMemory
    @State private var isHovering: Bool = false
    @State private var editedContent: String

    init(memory: APIMemory) {
        self.memory = memory
        self._editedContent = State(initialValue: memory.content)
    }

    var isEditing: Bool {
        editedContent != memory.content
    }

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
                Spacer()

                TextEditor(text: $editedContent)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .textEditorStyle(.plain)
                    .onSubmit {
                        commitEdit()
                    }
                    .onExitCommand {
                        commitEdit()
                    }

                Spacer()

                HStack(spacing: 8) {
                    Spacer()
                    cancelButton
                    confirmButton
                }
                .padding(10)
            }
        }
        .padding(.horizontal, 8)
        .overlay(
            deleteCardButton
                .visible(if: isHovering)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background.tertiary)
                .shadow(radius: isHovering ? 3 : 0)
        )
        .scaleEffect(isHovering ? 1.02 : 1)
        .whenHovered { hovering in
            withAnimation(AppConfig.snappy) {
                isHovering = hovering
            }
        }
    }

    // MARK: - Buttons

    var confirmButton: some View {
        Button(action: commitEdit) {
            Image(systemName: "checkmark")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(.chatButtonForeground)
                .visible(if: isEditing)
        }
        .buttonStyle(.plain)
    }

    var cancelButton: some View {
        Button(action: cancelEdit) {
            Image(systemName: "xmark")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(.chatButtonForeground)
                .visible(if: isEditing)
        }
        .buttonStyle(.plain)
    }

    var deleteCardButton: some View {
        VStack {
            HStack {
                Button(action: delete) {
                    Image(systemName: "xmark")
                        .resizable()
                        .padding(6)
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
    }

    func delete() {
        let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "MemoryView")

        withAnimation {
            MessageViewModel.shared.api_memories.removeAll { $0 == memory }
        }

        // DELETE chat
        Task {
            guard let url = URL(string: AppConfig.invisibility_api_base + "/memories/\(memory.id)") else {
                return
            }
            guard let token = UserDefaults.standard.string(forKey: "token") else {
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)

            logger.debug(String(data: data, encoding: .utf8) ?? "No data")
        }
    }

    func cancelEdit() {
        editedContent = memory.content
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
    }

    func commitEdit() {
        let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "MemoryView")
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)

        memory.content = editedContent
        guard let index = MessageViewModel.shared.api_memories.firstIndex(of: memory) else {
            logger.error("Memory not found")
            return
        }
        MessageViewModel.shared.api_memories[index].content = memory.content

        Task {
            guard let url = URL(string: AppConfig.invisibility_api_base + "/memories/\(memory.id)") else {
                return
            }

            guard let token = UserDefaults.standard.string(forKey: "token") else {
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let encoder = JSONEncoder()
            let payload = UpdateMemoryRequest(content: memory.content, grouping: memory.grouping?.rawValue)

            // Try encoding the payload to JSON data, handling any encoding errors
            do {
                let data = try encoder.encode(payload)
                request.httpBody = data
            } catch {
                logger.error("Failed to encode payload: \(error)")
                return
            }

            let (responseData, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("HTTP Response Status Code: \(httpResponse.statusCode)")
            }

            let responseString = String(data: responseData, encoding: .utf8) ?? "No data"
            logger.debug("Response Data: \(responseString)")
        }
    }
}

struct MemoryGrid: View {
    let memories: [APIMemory]
    @Binding var expandedGroup: String?

    var groupedMemories: [String: [APIMemory]] {
        Dictionary(grouping: memories, by: { $0.grouping?.rawValue ?? "" })
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
            ForEach(groupedMemories.keys.sorted(), id: \.self) { group in
                if let memories = groupedMemories[group]?.sorted(by: { $0.created_at > $1.created_at }) {
                    MemoryLeaderCard(memory: memories.first!) {
                        expandWithAnimation(group: group)
                    }
                }
            }
        }
    }

    private func expandWithAnimation(group: String) {
        withAnimation(AppConfig.easeInOut) {
            if expandedGroup == group {
                expandedGroup = nil
            } else {
                expandedGroup = group
            }
        }
    }
}

struct ExpandedGridView: View {
    let group: String
    let memories: [APIMemory]
    @Binding var expandedGroup: String?

    var body: some View {
        ScrollView {
            VStack {
                Image(systemName: memories.first?.grouping?.sfSymbol ?? "questionmark.circle")
                    .font(.title)

                Text(group)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(memories.sorted(by: { $0.created_at > $1.created_at }), id: \.id) { memory in
                        MemoryCard(memory: memory)
                            .frame(height: 170)
                    }
                }
                .padding(.top, 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .padding()
        .frame(width: .infinity, height: .infinity)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, cornerRadius: 16)
        )
        .onTapGesture { onTap() }
        .cornerRadius(16)
    }

    func onTap() {
        withAnimation(AppConfig.easeInOut) {
            expandedGroup = nil
        }
    }
}
