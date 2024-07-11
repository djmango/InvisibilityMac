import SwiftUI

struct MemoryView: View {
    @StateObject private var viewModel = MemoryViewModel()
    @State private var expandedGroup: String?
    @State private var expandedPosition: CGPoint = .zero

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    MemoryHeader(title: "My Memories", onRefresh: viewModel.fetchAPISync, onClose: viewModel.closeView, isRefreshing: viewModel.isRefreshing)
                    MemoryGrid(memories: viewModel.memories, expandedGroup: $expandedGroup, expandedPosition: $expandedPosition)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 25)
            }
            .background(Color.white.opacity(0.001))
            .onAppear { viewModel.fetchAPISync() }

            if expandedGroup != nil {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            expandedGroup = nil
                        }
                    }

                ExpandedGridView(group: expandedGroup!,
                                 memories: viewModel.memories.filter { $0.grouping?.rawValue == expandedGroup },
                                 position: expandedPosition)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct MemoryHeader: View {
    let title: String
    let onRefresh: () -> Void
    let onClose: () -> Void
    var isRefreshing: Bool

    var body: some View {
        HStack {
            Button(action: onRefresh) {
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

struct MemoryCard: View {
    let memory: APIMemory
    let isLeader: Bool
    let onTap: () -> Void
    @State private var isHovering: Bool = false

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
                Image(systemName: memory.grouping?.sfSymbol ?? "questionmark.circle")
                    .font(.title2)
                    .shadow(radius: 1)

                Text("\(memory.grouping?.rawValue ?? "Unknown")")
                    .font(.title3)
                    .bold()
                    .padding(.top, 2)

                Text(memory.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    // .lineLimit(2)
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
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
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

struct MemoryGrid: View {
    let memories: [APIMemory]
    @Binding var expandedGroup: String?
    @Binding var expandedPosition: CGPoint

    var groupedMemories: [String: [APIMemory]] {
        Dictionary(grouping: memories, by: { $0.grouping?.rawValue ?? "" })
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 350))], spacing: 16) {
            ForEach(groupedMemories.keys.sorted(), id: \.self) { group in
                if let memories = groupedMemories[group]?.sorted(by: { $0.created_at > $1.created_at }) {
                    MemoryCard(memory: memories.first!, isLeader: true) {
                        expandWithAnimation(group: group)
                    }
                    .overlay(
                        GeometryReader { geo -> Color in
                            let frame = geo.frame(in: .global)
                            DispatchQueue.main.async {
                                if expandedGroup == group {
                                    expandedPosition = CGPoint(x: frame.midX, y: frame.midY)
                                }
                            }
                            return Color.clear
                        }
                    )
                }
            }
        }
    }

    private func expandWithAnimation(group: String) {
        withAnimation(.spring()) {
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
    let position: CGPoint

    var body: some View {
        VStack(spacing: 16) {
            Text(group)
                .font(.title)
                .fontWeight(.bold)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(memories.sorted(by: { $0.created_at > $1.created_at }), id: \.id) { memory in
                        MemoryCard(memory: memory, isLeader: false, onTap: {})
                            .frame(height: 170)
                    }
                }
            }
        }
        .padding()
        .frame(width: 550, height: 600)
        .background(Color.white)
        .cornerRadius(30)
        .shadow(radius: 20)
        // .position(position)
        // .position(y: position.y)
        .offset(y: position.y - 350)
    }
}
