//
//  TabViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import Combine
import Foundation

class TabViewModel: ObservableObject {
    static let shared = TabViewModel()

    @Published private(set) var audioPlayerViewModel = AudioPlayerViewModel.shared
    @Published var tabs: [String] = []
    @Published var selectedTab: Int = 0

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        audioPlayerViewModel.$audio
            .sink { [weak self] audio in
                guard let self else { return }
                if audio != nil {
                    // tabs = ["Messages", audio.name]
                    tabs = ["Messages", "Audio"]
                } else {
                    if CommandViewModel.shared.selectedChat != nil {
                        tabs = ["Messages"]
                    } else {
                        tabs = []
                    }
                }
            }
            .store(in: &cancellables)
    }
}
