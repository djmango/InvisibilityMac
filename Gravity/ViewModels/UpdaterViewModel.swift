//
//  UpdaterViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/11/24.
//

import Combine
import Sparkle
import SwiftUI

// This view model class publishes when new updates can be checked by the user
final class UpdaterViewModel: ObservableObject {
    static let shared = UpdaterViewModel()

    private var cancellable: AnyCancellable?
    public let updater: SPUUpdater

    @Published var canCheckForUpdates = false

    private init() {
        let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        self.updater = updaterController.updater

        cancellable = updater.publisher(for: \.canCheckForUpdates)
            .assign(to: \.canCheckForUpdates, on: self)
    }
}
