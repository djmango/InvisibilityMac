//
//  MessageScrollView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/9/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import ScrollKit
import SwiftUI

struct MessageScrollView: View {
    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared

    @State private var offset = CGPoint.zero
    // @State private var visibleRatio = CGFloat.zero

    func handleOffset(_ scrollOffset: CGPoint, visibleHeaderRatio _: CGFloat) {
        self.offset = scrollOffset
        // self.visibleRatio = visibleHeaderRatio
    }

    var body: some View {
        let _ = Self._printChanges()
        ScrollViewWithStickyHeader(
            header: { Rectangle().hidden() },
            // These magic numbers are not perfect, esp the 7 but it works ok for now
            headerHeight: messageViewModel.messages.count > 7 ? 10 : max(10, messageViewModel.windowHeight - 205),
            headerMinHeight: 0,
            onScroll: handleOffset
        ) {
            VStack(alignment: .trailing, spacing: 5) {
                ForEach(messageViewModel.messages) { message in
                    // Generate the view for the individual message.
                    MessageListItemView(message: message)
                        .id(message.id)
                        .sentryTrace("MessageListItemView")
                }
            }
        }
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
        .scrollContentBackground(.hidden)
        .scrollIndicators(.never)
        .defaultScrollAnchor(.bottom)
    }
}
