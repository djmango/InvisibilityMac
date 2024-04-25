//
//  SettingsModelListView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/22/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

import SwiftUIReorderableForEach
import UniformTypeIdentifiers

struct SettingsModelListView: View {
    @AppStorage("llmModelName") private var llmModel = LLMModelRepository.claude3Opus.model.human_name

    @State var models: [LLMModel] = []
    @State var allowReordering = true

    init() {
        _models = State(initialValue: LLMModelRepository.allModels)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ReorderableForEach($models, allowReordering: $allowReordering) { model, _ in
                    @AppStorage("llmEnabled_\(model.human_name)") var enabled = false
                    HStack {
                        // Three dashes to indicate reordering
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(.gray)
                            .padding(.trailing, 5)

                        Text(model.human_name)

                        Spacer()

                        Toggle("", isOn: Binding(get: {
                            enabled
                        }, set: { newValue in
                            enabled = newValue
                        }))
                        .toggleStyle(.switch)
                    }
                    .id(model)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        }
                    }
                }
                // To allow other drag and drops throughout the app
                .hide(if: !SettingsViewModel.shared.showSettings, removeCompletely: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    // .fill(Color.gray.opacity(0.1))
                    .foregroundColor(Color("ChatButtonBackgroundColor"))
                    // .fill(Color("ChatButtonBackgroundColor"))
                    .shadow(radius: 2)
            )
            .padding()
        }
    }
}
