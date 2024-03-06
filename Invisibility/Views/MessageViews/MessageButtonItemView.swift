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

    @State private var isHovering: Bool = false
    @State private var isAnimating: Bool = false

    init(label: String, icon: String, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
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
                    .animation(.snappy, value: isAnimating)

                Text(label)
                    .font(.title3)
                    .foregroundColor(Color("ChatButtonForegroundColor"))
                    .hide(if: !isHovering, removeCompletely: true)
                    .animation(.snappy, value: isHovering)
                    .padding(.trailing, 8)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 100))
        .onTapGesture {
            actionWrapped()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 100)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.snappy, value: isHovering)
        .animation(.snappy, value: label)
        // .changeEffect(.spin, value: isAnimating)
        // .changeEffect(
        //     .spray(origin: UnitPoint(x: 0.25, y: 0.5)) {
        //         Image(systemName: icon)
        //     }, value: isAnimating
        // )
        // .conditionalEffect(.repeat(.wiggle(rate: .fast), every: .seconds(1)), condition: isAnimating)
        // .conditionalEffect(.glow, condition: isAnimating)
        .buttonStyle(.plain)
    }

    func actionWrapped() {
        // withAnimation(.default) {
        //     isAnimating = true
        // }
        action()
        // Reset after the animation completes
        // DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        //     isAnimating = false
        // }
    }
}
