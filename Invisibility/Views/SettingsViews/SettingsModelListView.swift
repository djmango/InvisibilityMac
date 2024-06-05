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
    @AppStorage("llmModelName") private var llmModel = LLMModelRepository.gpt4o.model.human_name

    @State var models: [LLMModel] = [] {
        didSet {
            // Print the index of all the models
            for (index, model) in models.enumerated() {
                print("Model at index \(index): \(model)")
            }
        }
    }

    @State var allowReordering = true

    init() {
        _models = State(initialValue: LLMModelRepository.allModels)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ReorderableForEach($models, allowReordering: $allowReordering) { model, draggging in
                    @AppStorage("llmEnabled_\(model.human_name)") var enabled = false
                    HStack {
                        // Three dashes to indicate reordering
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(.gray)
                            .padding(.trailing, 5)

                        Text(model.human_name)
                            .textSelection(.disabled)

                        Spacer()

                        Toggle("", isOn: Binding(get: {
                            enabled
                        }, set: { newValue in
                            enabled = newValue
                        }))
                        .toggleStyle(.switch)
                    }
                    .padding(.vertical, 4)
                    .background(
                        Rectangle()
                            .foregroundColor(Color.white.opacity(0.001))
                    )
                    .opacity(draggging ? 0 : 1)
                    .id(model)
                }
            }
            // To allow other drag and drops throughout the app
            .hide(if: !SettingsViewModel.shared.isShowingSettings, removeCompletely: true)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(Color("ChatButtonBackgroundColor"))
                    .shadow(radius: 2)
            )
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
    }
}
