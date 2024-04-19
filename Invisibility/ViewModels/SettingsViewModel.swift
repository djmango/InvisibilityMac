//
//  SettingsViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/18/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog

final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "SettingsViewModel")

    @Published var showSettings = false

    private init() {}
}
