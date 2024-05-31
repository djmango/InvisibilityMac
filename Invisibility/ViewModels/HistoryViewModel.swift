//
//  HistoryViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/30/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog

final class HistoryViewModel: ObservableObject {
    static let shared = HistoryViewModel()

    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "HistoryViewModel")

    @Published var isShowingHistory = false

    private init() {}
}
