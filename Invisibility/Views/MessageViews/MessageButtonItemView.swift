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
    private let shortcut_hint: String

    @AppStorage("animateButtons") private var animateButtons: Bool = true
    @AppStorage("shortcutHints") private var shortcutHints: Bool = true

    @State private var isPressed: Bool = false
    @State private var isHovering: Bool = false
    @Binding private var whoIsHovering: String?

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared

    init(label: String, icon: String, shortcut_hint: String, whoIsHovering: Binding<String?>, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.shortcut_hint = shortcut_hint
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
                        .visible(if: !shortcutViewModel.modifierFlags.contains(.command) || !shortcutHints, removeCompletely: true)

                    Text(shortcut_hint)
                        .font(.title3)
                        .foregroundColor(Color("ChatButtonForegroundColor"))
                        .visible(if: shortcutViewModel.modifierFlags.contains(.command) && shortcutHints, removeCompletely: true)
                }

                Text(label)
                    .font(.title3)
                    .foregroundColor(Color("ChatButtonForegroundColor"))
                    .visible(if: isHovering && animateButtons, removeCompletely: true)
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
