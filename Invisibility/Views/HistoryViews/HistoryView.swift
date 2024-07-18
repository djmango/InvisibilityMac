//
//  HistoryView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel = HistoryViewModel()
    @State private var searchText: String = ""
    var body: some View {
        ScrollView {
            Spacer()
            ForEach(viewModel.categoryOrder, id: \.self) { key in
                if let chats = viewModel.groupedChats[key], !chats.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(key)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.7), radius: 2)

                        ForEach(chats) { chat in
                            HistoryCardView(chat: chat)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            Spacer()
        }
        .background(Rectangle().fill(Color.white.opacity(0.001)))
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.005),
                    .init(color: .black, location: 0.995),
                    .init(color: .clear, location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
