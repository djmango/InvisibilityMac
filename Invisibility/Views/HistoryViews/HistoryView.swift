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

    var startOfWeek: Date? {
        let cal = Calendar.current
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components)
    }

    var startOfMonth: Date? {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month], from: self)
        return cal.date(from: components)
    }

    func isInSameWeek(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .weekOfYear)
    }

    func isInSameMonth(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self.startOfDay) ?? self
    }
}

struct HistoryView: View {
    @ObservedObject private var messageViewModel = MessageViewModel.shared

    // Define the desired order of categories
    private let categoryOrder: [String] = [
        "Today",
        "This Week",
        "Last Week",
        "Last 30 Days",
        "Older",
    ]

    // Seperate the chats into lists per logical group
    private var groupedChats: [String: [APIChat]] {
        let now = Date()
        var categories: [String: [APIChat]] = [
            "Today": [],
            "This Week": [],
            "Last Week": [],
            "Last 30 Days": [],
            "Older": [],
        ]

        // for chat in messageViewModel.api_chats {
        for chat in messageViewModel.sortedChatsByLastMessage() {
            let chatDate = messageViewModel.lastMessageFor(chat: chat)?.created_at ?? chat.created_at

            if Calendar.current.isDateInToday(chatDate) {
                categories["Today"]?.append(chat)
                continue
            }

            if let startOfWeek = now.startOfWeek, let chatWeek = chatDate.startOfWeek, chatDate >= startOfWeek, chatDate < now {
                categories["This Week"]?.append(chat)
                continue
            }

            let lastWeekStart = now.daysAgo(14).startOfWeek ?? now
            let thisWeekStart = now.startOfWeek ?? now
            if chatDate >= lastWeekStart, chatDate < thisWeekStart {
                categories["Last Week"]?.append(chat)
                continue
            }

            let thirtyDaysAgo = now.daysAgo(30)
            if chatDate >= thirtyDaysAgo, chatDate < now {
                categories["Last 30 Days"]?.append(chat)
                continue
            }

            categories["Older"]?.append(chat)
        }

        return categories
    }

    var body: some View {
        ScrollView {
            Spacer()
            ForEach(categoryOrder, id: \.self) { key in
                if let chats = groupedChats[key], !chats.isEmpty {
                    HistorySectionView(title: key, chats: chats, messageViewModel: messageViewModel)
                    // .rotationEffect(.degrees(180))
                }
            }
            .padding(.horizontal, 10)
            Spacer()
        }
        // .rotationEffect(.degrees(180))
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

struct HistorySectionView: View {
    let title: String
    let chats: [APIChat]
    let messageViewModel: MessageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.7), radius: 2)

            ForEach(chats) { chat in
                HistoryCardView(
                    chat: chat,
                    last_message: messageViewModel.api_messages.filter { $0.chat_id == chat.id }.last
                )
            }
        }
    }
}
