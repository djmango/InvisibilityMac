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

    let enabledModelsCount = LLMManager.shared.enabledModels.count

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

            // Add padding on each side so the slider never goes to either edge
            CompactSlider(value: Binding(
                get: { Float(LLMManager.shared.enabledModelIndex) },
                set: { LLMManager.shared.setModel(index: Int($0)) }
            ), in: 0 ... (Float(enabledModelsCount) - 1), step: 1, state: $sliderState) {}
                .compactSliderStyle(CustomCompactSliderStyle())
                .overlay(
                    Text(LLMManager.shared.model.human_name)
                        .foregroundColor(.white)
                        .padding(8)
                        .frame(width: 110)
                        .fixedSize(horizontal: true, vertical: false)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .background(Capsule().fill(.accent))
                        // .offset(x: sliderState.dragLocationX.lower)
                        .offset(x: min(max(-130, sliderState.dragLocationX.lower), 130))
                        .allowsHitTesting(false)
                )
                .visible(if: isHovering, removeCompletely: true)
        }
        .padding(6)
        // .padding(.horizontal, isHovering ? 40 : 0)
        .contentShape(RoundedRectangle(cornerRadius: 21))
        .background(
            RoundedRectangle(cornerRadius: 21)
                .fill(Color("ChatButtonBackgroundColor"))
                .visible(if: !isHovering, removeCompletely: true)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 21)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                .visible(if: !isHovering, removeCompletely: true)
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

struct CustomCompactSliderStyle: CompactSliderStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // .foregroundColor(
            //     configuration.isHovering || configuration.isDragging ? .orange : .black
            // )
            // .accentColor(.orange)
            // Gradient(colors: [Color("InvisGrad1"), Color("InvisGrad2")]) :
            .compactSliderSecondaryAppearance(
                // progressShapeStyle: Color.clear,
                progressShapeStyle: LinearGradient(
                    colors: [Color("InvisGrad1"), Color("InvisGrad2")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                // focusedProgressShapeStyle: Color.clear,
                focusedProgressShapeStyle: LinearGradient(
                    colors: [Color("InvisGrad1"), Color("InvisGrad2")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                // handleColor: .accent,
                handleColor: Color("ChatButtonForegroundColor"),
                scaleColor: Color("ChatButtonForegroundColor"),
                secondaryScaleColor: Color("ChatButtonForegroundColor")
            )
            .clipShape(RoundedRectangle(cornerRadius: 21))
    }
}
