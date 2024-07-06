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
    private let label: String?
    private let icon: String
    private let shortcut_hint: String?
    private let iconColor: Color
    private let size: CGFloat

    @AppStorage("animateButtons") private var animateButtons: Bool = true
    @AppStorage("shortcutHints") private var shortcutHints: Bool = true

    @State private var isPressed: Bool = false
    @State private var isHovering: Bool = false

    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared

    init(label: String?,
         icon: String,
         shortcut_hint: String?,
         iconColor: Color = .chatButtonForeground,
         size: CGFloat = 18,
         action: @escaping () -> Void)
    {
        self.label = label
        self.icon = icon
        self.shortcut_hint = shortcut_hint
        self.iconColor = iconColor
        self.action = action
        self.size = size
    }

    var body: some View {
        Button(action: actionWrapped) {
            HStack(spacing: 0) {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundColor(iconColor)
                    .visible(
                        if: !shortcutViewModel.isCommandPressed || !shortcutHints || shortcut_hint == nil,
                        removeCompletely: true
                    )

                if let shortcut_hint {
                    Text(shortcut_hint)
                        .font(.title3)
                        .foregroundColor(.chatButtonForeground)
                        .visible(
                            if: shortcutViewModel.isCommandPressed && shortcutHints,
                            removeCompletely: true
                        )
                        .truncationMode(.head)
                        .kerning(-1)
                }

                if let label {
                    Text(label)
                        .font(.title3)
                        .foregroundColor(.chatButtonForeground)
                        .visible(if: isHovering && animateButtons && !shortcutViewModel.isCommandPressed, removeCompletely: true)
                        .padding(.leading, 8)
                }
            }
            .frame(height: size)
            .padding(8)
            .contentShape(RoundedRectangle(cornerRadius: 100))
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color(.chatButtonBackground))
            )
        }
        .whenHovered { hovering in
            withAnimation(AppConfig.snappy) {
                isHovering = hovering
            }
        }
        .buttonStyle(.plain)
        .animation(AppConfig.snappy, value: label)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }

    func actionWrapped() {
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPressed = false
        }
        action()
    }
}
