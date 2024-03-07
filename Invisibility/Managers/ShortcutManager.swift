//
//  ShortcutManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import Foundation
import KeyboardShortcuts
import OSLog

extension KeyboardShortcuts.Name {
    static let summon = Self("summon", default: .init(.g, modifiers: [.command]))
    static let screenshot = Self("screenshot", default: .init(.one, modifiers: [.command, .shift]))
}
