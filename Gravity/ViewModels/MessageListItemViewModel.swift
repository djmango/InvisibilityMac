//
//  MessageListItemViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import Foundation
import SwiftData

// class MessageListItemViewModel: ObservableObject {
//     @Query var messages: [Message]
//     private var messageRaw: Message  // Assuming you have this property
//     @Published var message: Message?

//     init() {
//         _messages.onChange { [weak self] in
//             self?.updateMessage()
//         }
//     }

//     private func updateMessage() {
//         self.message = messages.first { $0.id == messageRaw.id }
//     }
// }
