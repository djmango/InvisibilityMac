//
//  ChatModelPicker.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/21/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import CompactSlider
import SwiftUI

struct ChatModelPicker: View {
    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared

    @State private var sliderState: CompactSliderState = .zero
    @State private var isHovering: Bool = false
    @Binding var whoIsHovering: String?

    @AppStorage("shortcutHints") private var shortcutHints: Bool = true

    init(whoIsHovering: Binding<String?>) {
        self._whoIsHovering = whoIsHovering
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Image(systemName: "globe")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color("ChatButtonForegroundColor"))
                    .visible(if: (!ShortcutViewModel.shared.modifierFlags.contains(.command) || !shortcutHints) && !isHovering, removeCompletely: true)

                Text("⌘ ⇧ M")
                    .font(.title3)
                    .foregroundColor(Color("ChatButtonForegroundColor"))
                    .visible(if: ShortcutViewModel.shared.modifierFlags.contains(.command) && shortcutHints && !isHovering, removeCompletely: true)
            }

            CompactSlider(value: Binding(
                get: { Float(LLMManager.shared.modelIndex) },
                set: { LLMManager.shared.setModel(index: Int($0)) }
            ), in: 0 ... 5, step: 1, state: $sliderState) {}
                .overlay(
                    Text(LLMManager.shared.model.human_name)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Capsule().fill(Color.blue)
                        )
                        .offset(x: sliderState.dragLocationX.lower)
                        .allowsHitTesting(false)
                )
                .visible(if: isHovering, removeCompletely: true)
        }
        .padding(8)
        .contentShape(RoundedRectangle(cornerRadius: 21))
        .background(
            RoundedRectangle(cornerRadius: 21)
                .fill(Color("ChatButtonBackgroundColor"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 21)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                whoIsHovering = "Models"
            } else {
                whoIsHovering = nil
            }
        }
        .animation(AppConfig.snappy, value: whoIsHovering)
        .animation(AppConfig.snappy, value: ShortcutViewModel.shared.modifierFlags)
    }
}
