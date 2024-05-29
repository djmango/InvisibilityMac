//
//  HistoryCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct HistoryCardView: View {
    let chat: APIChat

    var messages: [APIMessage] {
        MessageViewModel.shared.api_messages.filter { $0.chat_id == chat.id }
    }

    @State private var isHovered: Bool = false

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)

            VStack(alignment: .leading) {
                HStack {
                    Text(chat.name)
                        .font(.title2)

                    Spacer()

                    Text(chat.created_at, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Text(messages.last?.text ?? "")
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .onHover {
            if $0 {
                isHovered = true
            } else {
                isHovered = false
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
        .frame(height: 80, alignment: .leading)
    }
}
