//
//  ChatModelPicker.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/21/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import CompactSlider
import SwiftUI

enum SliderValue: String, CaseIterable {
    case george, lenny, rabbit

    var value: Double {
        switch self {
        case .george:
            0.0
        case .lenny:
            1.0
        case .rabbit:
            2.0
        }
    }

    init(value: Double) {
        switch value {
        case 0.0:
            self = .george
        case 1.0:
            self = .lenny
        default:
            self = .rabbit
        }
    }
}

struct ChatModelPicker: View {
    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared

    @State private var selectedValue: SliderValue = .lenny
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
                get: { selectedValue.value },
                set: { selectedValue = SliderValue(value: $0) }
            ), in: 0 ... 2, step: 1, state: $sliderState) {}
                .overlay(
                    Text(selectedValue.rawValue.capitalized)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Capsule().fill(Color.blue)
                        )
                        .offset(x: sliderState.dragLocationX.lower)
                        // .offset(x: sliderState.dragLocationX.lower)
                        .allowsHitTesting(false)
                )
                .visible(if: isHovering, removeCompletely: true)
        }
        .padding(8)
        .contentShape(RoundedRectangle(cornerRadius: 100))
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
                whoIsHovering = "Models"
            } else {
                whoIsHovering = nil
            }
        }
        .animation(AppConfig.snappy, value: whoIsHovering)
        .animation(AppConfig.snappy, value: ShortcutViewModel.shared.modifierFlags)
    }
}
