//
//  WindowManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/19/24.
//

import Foundation

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    // Properties to control window size and position
    @Published var shouldAdjustWindow: Bool = false

    private init() {}
}
