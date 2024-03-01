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
    static let screenshot = Self("screenshot")
}

import Foundation

class KeypressManager: ObservableObject {
    let logger = Logger(subsystem: "so.invisibility.app", category: "KeypressManager")

    static let shared = KeypressManager()

    private init() {}
}
