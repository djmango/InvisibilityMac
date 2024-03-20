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
    private let shortcut_icons: [String]

    @State private var isPressed: Bool = false
    @State private var isHovering: Bool = false
    @Binding private var whoIsHovering: String?

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared

    init(label: String, icon: String, shortcut_icons: [String], whoIsHovering: Binding<String?>, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.shortcut_icons = shortcut_icons
        self._whoIsHovering = whoIsHovering
        self.action = action
    }

    var body: some View {
        Button(action: actionWrapped) {
            HStack(spacing: 0) {
                HStack {
                    Image(systemName: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundColor(Color("ChatButtonForegroundColor"))
                        .visible(if: !shortcutViewModel.modifierFlags.contains(.command), removeCompletely: true)

                    ForEach(shortcut_icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color("ChatButtonForegroundColor"))
                    }
                    .visible(if: shortcutViewModel.modifierFlags.contains(.command), removeCompletely: true)
                }

                Text(label)
                    .font(.title3)
                    .foregroundColor(Color("ChatButtonForegroundColor"))
                    .hide(if: !isHovering, removeCompletely: true)
                    .padding(.leading, 8)
            }
            .padding(8)
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
                whoIsHovering = label
            } else {
                whoIsHovering = nil
            }
        }
        .animation(AppConfig.snappy, value: label)
        .animation(AppConfig.snappy, value: isHovering)
        .animation(AppConfig.snappy, value: shortcutViewModel.modifierFlags)
        .buttonStyle(.plain)
        // .changeEffect(.glow, value: isHovering, isEnabled: isHovering)
        // .changeEffect(.jump(height: 10), value: isPressed)
        // .scaleEffect(isPressed ? 0.9 : 1.0)
        // .opacity(isPressed ? 0.8 : 1.0)
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
