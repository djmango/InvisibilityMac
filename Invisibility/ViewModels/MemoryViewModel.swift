//
//  MemoryViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/28/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

class MemoryViewModel: ObservableObject {
    @Published var memories: [APIMemory] = []

    private let mainWindowViewModel: MainWindowViewModel = .shared

    func fetchMemories() {
        // TODO: Implement API call to fetch memories
        // For now, we'll use sample data
        memories = [
            APIMemory(id: UUID(), userId: "user1", content: "Invisibility was featured in an article and you were personally mentioned!", emoji: "📰", createdAt: Date(), updatedAt: Date(), deletedAt: nil, memoryPromptId: nil),
            APIMemory(id: UUID(), userId: "user1", content: "You discovered the Bukk E-Motorcycle as your new pick for best looking bike of the year", emoji: "🏍️", createdAt: Date(), updatedAt: Date(), deletedAt: nil, memoryPromptId: nil),
            APIMemory(id: UUID(), userId: "user1", content: "Your brand's colors are a mix of different shades of Blue", emoji: "🎨", createdAt: Date(), updatedAt: Date(), deletedAt: nil, memoryPromptId: nil),
            APIMemory(id: UUID(), userId: "user1", content: "You stayed in SF for a couple weeks while building at the WeWork office during the Pioneer Summit!", emoji: "🌉", createdAt: Date(), updatedAt: Date(), deletedAt: nil, memoryPromptId: nil),
        ]
    }

    func deleteMemory(_ memory: APIMemory) {
        // TODO: Implement API call to delete memory
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories.remove(at: index)
        }
    }

    @MainActor func closeView() {
        _ = mainWindowViewModel.changeView(to: .chat)
    }
}
