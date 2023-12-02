import Combine
import Sparkle
import SwiftUI

@Observable
final class UpdaterViewModel {
    private var cancellable: AnyCancellable?

    var canCheckForUpdates = false
    
    init(_ updater: SPUUpdater) {
        cancellable = updater.publisher(for: \.canCheckForUpdates)
            .assign(to: \.canCheckForUpdates, on: self)
    }
}
