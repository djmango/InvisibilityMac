//
//  ChatWebInputViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/9/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SwiftUI

final class ChatWebInputViewModel: ObservableObject {
    static let shared = ChatWebInputViewModel()

    // The text content of the chat field
    public var text: String = ""

    /// This is a hack to update the text field rendering when the text is cleared
    @Published public var clearToggle: Bool = false

    /// The height of the text field.
    @Published public var height: CGFloat = 52

    private init() {}

    func clearText() {
        self.text = ""
        self.clearToggle.toggle()
    }
}
