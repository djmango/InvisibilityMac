//
//  ShortcutViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/20/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import AppKit
import Foundation
import KeyboardShortcuts
import OSLog

extension KeyboardShortcuts.Name {
    static let summon = Self("summon", default: .init(.g, modifiers: [.command]))
    static let screenshot = Self("screenshot", default: .init(.one, modifiers: [.command, .shift]))
}

@Observable
final class ShortcutViewModel: ObservableObject {
    static let shared = ShortcutViewModel()

    private let logger = Logger(subsystem: "so.invisibility.app", category: "ShortcutViewModel")

    public var commandKeyPressed: Bool = false
    public var modifierFlags: NSEvent.ModifierFlags = []

    private init() {}
}
