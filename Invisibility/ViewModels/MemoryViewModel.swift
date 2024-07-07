//
//  MemoryViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/28/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SwiftUI

class MemoryViewModel: ObservableObject {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "MemoryViewModel")

    @Published var memories: [APIMemory] = []
    @Published var isRefreshing: Bool = false

    private let mainWindowViewModel: MainWindowViewModel = .shared

    @AppStorage("token") private var token: String?

    func fetchAPISync() { Task { await fetchAPI() } }

    func fetchAPI() async {
        DispatchQueue.main.async { self.isRefreshing = true }
        defer { DispatchQueue.main.async { withAnimation { self.isRefreshing = false } } }
        let url = URL(string: AppConfig.invisibility_api_base + "/memories/")!

        guard let token else {
            logger.warning("No token for fetch")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = iso8601Decoder()
            let fetched = try decoder.decode([APIMemory].self, from: data)
            DispatchQueue.main.async {
                self.memories = fetched.sorted(by: { $0.grouping ?? "" < $1.grouping ?? "" })
                self.logger.debug("Fetched memories \(self.memories.count)")
            }
        } catch {
            logger.error("Failed to fetch memories from API: \(error)")
        }
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
