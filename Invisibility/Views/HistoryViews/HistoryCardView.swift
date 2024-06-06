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
    @State private var whoIsHovering: String?
    private var historyViewModel: HistoryViewModel = HistoryViewModel.shared
    private var chatViewModel: ChatViewModel = ChatViewModel.shared

    init(chat: APIChat, last_message: APIMessage?) {
        self.chat = chat
        self.last_message = last_message
    }

    func formattedDate(_ date: Date) -> String {
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateStyle = .long
        dateTimeFormatter.timeStyle = .short
        return dateTimeFormatter.string(from: date)
    }

    var body: some View {
        HStack {
            // Rounded blue line
            RoundedRectangle(cornerRadius: 5)
                .fill(Color("HistoryColor"))
                .frame(width: 5)
                .padding(.trailing, 5)

            VStack(alignment: .leading) {
                HStack {
                    Text(chat.name)
                        .font(.title3)

                    Button(action: {
                        print("Rename chat: \(chat.id)")
                    }) {
                        Image(systemName: "pencil")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 12, height: 12)
                    .visible(if: isHovered)

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
        // NOTE: the order of these 3 elements, stroke -> background -> overlay is important, it creates the nicest effect
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
                .shadow(radius: 2)
        )
        .overlay(
            // The X delete button
            HStack {
                VStack {
                    Button(action: {
                        print("Delete chat: \(chat.id)")
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .padding(5)
                            .foregroundColor(.chatButtonForeground)
                            .clipShape(Circle())
                    }
                    .overlay(
                        Circle()
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .background(
                        Circle()
                            .fill(Color.cardBackground)
                            .shadow(radius: 2)
                    )
                    .buttonStyle(.plain)
                    .frame(width: 21, height: 21)
                    .padding(.leading, -5)
                    .padding(.top, -5)

                    Spacer()
                }
                Spacer()
            }
            .visible(if: isHovered)
        )
        .onHover {
            if $0 {
                isHovered = true
                // Preemtively load the chat, snappier!
                // Wait until the hover animation is done to show the history
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Check if still hovered
                    if isHovered {
                        print("Switching to chat: \(chat.id)")
                        chatViewModel.switchChat(chat)
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovered = false
                }
            }
        }
        .onTapGesture {
            chatViewModel.switchChat(chat)
            withAnimation(AppConfig.snappy) {
                historyViewModel.isShowingHistory = false
            }
        }
    }
}
