//
//  HistoryView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

struct HistoryView: View {
    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared

    @Binding var isShowingHistory: Bool

    init(isShowingHistory: Binding<Bool>) {
        self._isShowingHistory = isShowingHistory
    }

    // Seperate the chats into lists per day
    // private var chatsByDay: [[APIChat]] {
    //     let grouped = Dictionary(grouping: messageViewModel.api_chats, by: { $0.created_at.startOfDay })
    //     return Array(grouped.values)
    // }

    var body: some View {
        ScrollView {
            Spacer()
            // Sort by date reverse
            ForEach(messageViewModel.api_chats.sorted { $0.created_at > $1.created_at }) { chat in
                HistoryCardView(
                    chat: chat,
                    last_message: messageViewModel.api_messages.filter { $0.chat_id == chat.id }.last,
                    isShowingHistory: $isShowingHistory
                )
                .rotationEffect(.degrees(180))
            }
            .padding(.horizontal, 10)
            Spacer()
        }
        // Upside down hack
        .rotationEffect(.degrees(180))
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.005), // Finish fading in
                    .init(color: .black, location: 0.995), // Start fading out
                    .init(color: .clear, location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// struct ChatDateSectionView: View {
//     let chats: [APIChat]

//     private var created_at: Date {
//         chats.first?.created_at ?? Date()
//     }

//     var body: some View {
//         VStack(alignment: .leading, spacing: 8) {
//             Text(created_at, style: .date)
//                 .font(.title3)
//                 .foregroundColor(.primary)

//             ForEach(chats) { chat in
//                 HistoryCardView(chat: chat)
//             }
//         }
//     }
// }
