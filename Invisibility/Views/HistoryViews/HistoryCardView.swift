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

    var body: some View {
        HStack {
            // Rounded blue line
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.accentColor)
                .frame(width: 5)

            VStack(alignment: .leading) {
                HStack {
                    Text(chat.name)
                        .font(.title3)

                    Spacer()

                    Text(last_message?.created_at ?? Date(), style: .time)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 5)

                Spacer()

                Text(last_message?.text ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.bottom, 5)
            }
        }
        .frame(height: 65)
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
                MessageViewModel.shared.switchChat(chat)
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
