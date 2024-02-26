//
//  MessageButtonItemView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct MessageButtonItemView: View {
    private let action: () -> Void
    private let label: String
    private let icon: String

    @State private var isHovering: Bool = false

    init(label: String, icon: String, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color("ChatButtonForegroundColor"))
                    .padding(8)

                Text(label)
                    // .font(.system(size: 12))
                    .font(.title3)
                    .foregroundColor(Color("ChatButtonForegroundColor"))
                    .hide(if: !isHovering, removeCompletely: true)
                    .animation(.snappy, value: isHovering)
                    .padding(.trailing, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color("ChatButtonBackgroundColor"))
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.snappy, value: isHovering)
        .buttonStyle(.plain)
    }
}
