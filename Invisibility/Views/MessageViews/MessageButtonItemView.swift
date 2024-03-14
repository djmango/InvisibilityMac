//
//  MessageButtonItemView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Pow
import SwiftUI

struct MessageButtonItemView: View {
    private let action: () -> Void
    private let label: String
    private let icon: String

    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModel.shared

    @Binding var isHovering: Bool

    init(label: String, icon: String, isHovering: Binding<Bool>, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self._isHovering = isHovering
        self.action = action
    }

    var body: some View {
        Button(action: actionWrapped) {
            HStack(spacing: 0) {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color("ChatButtonForegroundColor"))
                    .padding(8)

                Text(label)
                    .font(.title3)
                    .foregroundColor(Color("ChatButtonForegroundColor"))
                    .hide(if: !isHovering, removeCompletely: true)
                    .animation(.snappy, value: isHovering)
                    .padding(.trailing, 8)
            }
            .contentShape(RoundedRectangle(cornerRadius: 100))
        }
        .background(
            RoundedRectangle(cornerRadius: 100)
                .fill(Color("ChatButtonBackgroundColor"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 100)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                messageViewModel.whoIsHovering = label
            } else {
                messageViewModel.whoIsHovering = nil
            }
        }
        .animation(.snappy, value: isHovering)
        .animation(.snappy, value: label)
        .buttonStyle(.plain)
    }

    func actionWrapped() {
        action()
    }
}
