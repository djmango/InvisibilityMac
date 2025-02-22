//
//  MemoryViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/28/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

class MemoryViewModel: ObservableObject {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "MemoryViewModel")

    @Published var memories: [APIMemory] = []
    @Published var isRefreshing: Bool = false

    private let mainWindowViewModel: MainWindowViewModel = .shared
    private let messageViewModel: MessageViewModel = .shared

    private var cancellables = Set<AnyCancellable>()

    @AppStorage("token") private var token: String?

    init() {
        messageViewModel.$api_memories
            .sink { [weak self] memories in
                self?.memories = memories
            }
            .store(in: &cancellables)
    }

    func fetchAPISync() { Task { await fetchAPI() } }

    func fetchAPI() async {
        DispatchQueue.main.async { self.isRefreshing = true }
        defer { DispatchQueue.main.async { withAnimation { self.isRefreshing = false } } }
        await messageViewModel.fetchAPI()
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
