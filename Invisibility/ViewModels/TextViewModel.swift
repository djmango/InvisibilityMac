//
//  TextViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/9/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SwiftUI

func getCharDifferences(_ str1: String, _ str2: String) -> [String] {
    var differences: [String] = []
    let arr1 = Array(str1)
    let arr2 = Array(str2)

    var i = 0
    var j = 0

    while i < arr1.count, j < arr2.count {
        if arr1[i] != arr2[j] {
            differences.append(String(arr2[j]))
            j += 1
        } else {
            i += 1
            j += 1
        }
    }

    while j < arr2.count {
        differences.append(String(arr2[j]))
        j += 1
    }

    return differences
}

final class TextViewModel: ObservableObject {
    static let shared = TextViewModel()

    // The text content of the chat field
    @Published public var text: String = "" {
        didSet { textDidChange() }
    }

    private var previousText: String = ""

    private init() {}

    func clearText() {
        self.text = ""
    }

    /// Function to be called every time the text changes
    /// This function is used to detect when the user presses the Enter key with the intention of sending a message
    private func textDidChange() {
        let differences = getCharDifferences(previousText, text)

        // Detect pastes
        // if differences.count > 1 {
        //     // If paste, scroll to bottom. Not perfect, because one could paste in the middle but oh well its okay TODO: fix
        //     DispatchQueue.main.async {
        //         ChatViewModel.shared.shouldScrollToBottom = true
        //     }
        // }

        if differences.last == "\n", differences.count == 1 {
            // Attempt to detect Shift key
            // We have to make sure its not a paste with a newline too
            if NSApp.currentEvent?.modifierFlags.contains(.shift) == false, NSApp.currentEvent?.modifierFlags.contains(.command) == false {
                // If Shift is not pressed, and a newline is added, submit
                Task { await MessageViewModel.shared.sendFromChat() }
                DispatchQueue.main.async {
                    ChatViewModel.shared.textHeight = ChatEditorView.minTextHeight // Reset height
                }
            }
            // If Shift is pressed, just allow the newline (normal behavior) and scroll to the bottom
            // For some reason this actually works how its supposed to, only scrolling to bottom if we are at bottom, actually keeping the newline in view no matter where we are
        }
        previousText = text // Update previous text state for next change
    }
}
