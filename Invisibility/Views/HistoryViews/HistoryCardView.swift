//
//  HistoryCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import MarkdownWebView
import SwiftUI

struct HistoryCardView: View {
    let chat: APIChat
    let last_message: APIMessage?

    @State private var isHovered: Bool = false
    @Binding var isShowingHistory: Bool

    init(chat: APIChat, last_message: APIMessage?, isShowingHistory: Binding<Bool>) {
        self.chat = chat
        self.last_message = last_message
        self._isShowingHistory = isShowingHistory
    }

    func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        if isToday {
            return timeFormatter.string(from: date)
        } else {
            let dateTimeFormatter = DateFormatter()
            dateTimeFormatter.dateStyle = .short
            dateTimeFormatter.timeStyle = .short
            return dateTimeFormatter.string(from: date)
        }
    }

    var body: some View {
        HStack {
            // Rounded blue line
            RoundedRectangle(cornerRadius: 5)
                .fill(Color("HistoryColor"))
                .frame(width: 5)

            VStack(alignment: .leading) {
                HStack {
                    Text(chat.name)
                        .font(.title3)

                    Spacer()

                    Text(formattedDate(last_message?.created_at ?? Date()))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(last_message?.text ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.bottom, 5)
            }
        }
        .frame(height: 60)
        .padding()
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .onHover {
            if $0 {
                withAnimation(AppConfig.snappy) {
                    isHovered = true
                }
                // Preemtively load the chat, snappier!
                // Wait until the hover animation is done to show the history
                // DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                //     print("Switching to chat: \(chat.id)")
                MessageViewModel.shared.switchChat(chat)
                // }
            } else {
                // TODO: make this smoother
                withAnimation(AppConfig.snappy) {
                    isHovered = false
                }
            }
        }
        .onTapGesture {
            MessageViewModel.shared.switchChat(chat)
            withAnimation(AppConfig.snappy) {
                isShowingHistory = false
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
    }
}
