//
//  MessageActionButtonView.swift
//  Invisibility
//
//  Created by Duy Khang Nguyen Truong on 7/12/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import PostHog
import Pow
import SwiftUI

struct MessageActionButtonItemView: View {
    private let action: () -> Void
    private let label: String?
    private let icon: String
    private let iconColor: Color
    private let size: CGFloat

    @AppStorage("animateButtons") private var animateButtons: Bool = true

    @State private var isPressed: Bool = false
    @State private var isHovering: Bool = false

    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared

    init(label: String?,
         icon: String,
         iconColor: Color = .chatButtonForeground,
         size: CGFloat = 18,
         action: @escaping () -> Void)
    {
        self.label = label
        self.icon = icon
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

                if let label {
                    Text(label)
                        .font(.title3)
                        .foregroundColor(.chatButtonForeground)
                        .padding(.leading, 8)
                }
            }
            .frame(height: size)
            .padding(8)
            .contentShape(RoundedRectangle(cornerRadius: 100))
        }
        .whenHovered { hovering in
            withAnimation(AppConfig.easeInOut) {
                isHovering = hovering
            }
        }
        .scaleEffect(isHovering ? 1.05 : 1.0)
        // .shadow(radius: isHovering ? 1 : 0)
        .buttonStyle(.plain)
        .animation(AppConfig.snappy, value: label)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }

    func actionWrapped() {
        defer { PostHogSDK.shared.capture("pressed_\(label ?? icon)") }
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPressed = false
        }
        action()
    }
}
