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

    var messages: [APIMessage] {
        MessageViewModel.shared.api_messages.filter { $0.chat_id == chat.id }
    }

    @State private var isHovered: Bool = false

    var body: some View {
        HStack {
            // Rounded blue line
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.accentColor)
                .frame(width: 5)

            VStack {
                HStack {
                    Text(chat.name)
                        .font(.title3)

                    Spacer()

                    Text(messages.last?.created_at ?? Date(), style: .time)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 5)

                Text(messages.last?.text ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)

                // TextField("Last message", text: .constant(messages.last?.text ?? ""))
                //     .font(.body)
                //     // .foregroundColor(.gray)
                //     .textFieldStyle(.plain)
                //     .disabled(true)
                // .frame(height: 50)
            }
        }
        .padding()
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .onHover {
            if $0 {
                withAnimation(AppConfig.snappy) {
                    isHovered = true
                }
            } else {
                withAnimation(AppConfig.snappy) {
                    isHovered = false
                }
            }
        }
        .onTapGesture {
            print("Switching to chat \(chat.name)")
            MessageViewModel.shared.switchChat(chat)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
    }
}
