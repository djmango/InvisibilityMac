//
//  TextViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/9/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

final class TextViewModel: ObservableObject {
    static let shared = TextViewModel()

    // The text content of the chat field
    @Published public var text: String = ""

    private init() {}
}
