//
//  CaptureViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/13/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

@MainActor
final class CaptureViewModel: ObservableObject {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "CaptureViewModel")

    static let shared = CaptureViewModel()

    private init() {
        // screenRecorder = ScreenRecorder()
    }

    @Published var isPickerActive = false
    @Published var isRunning = false
    @Published var isUnauthorized = false
    @Published var userStopped = false
    // @Published var pickerUpdate = false
    // @Published var screenRecorder: ScreenRecorder
}
