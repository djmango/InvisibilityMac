//
//  KeypressManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import Foundation
import KeyboardShortcuts
import OSLog

extension KeyboardShortcuts.Name {
    static let summon = Self("summon")
}

import Foundation

class KeypressManager: ObservableObject {
    let logger = Logger(subsystem: "so.invisibility.app", category: "KeypressManager")

    static let shared = KeypressManager()

    @Published var enterPressed: Bool = false

    private init() {}
}
