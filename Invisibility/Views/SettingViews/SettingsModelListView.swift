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
    @AppStorage("llmModelName") private var llmModel = LLMModels.claude3Opus.model.human_name

    @State var models: [LLMModels] = []
    @State var allowReordering = true

    init() {
        _models = State(initialValue: LLMModels.allCases)
    }

    var body: some View {
        VStack {
            ReorderableForEach($models, allowReordering: $allowReordering) { model, _ in
                Text(model.model.human_name)
                    .id(model)
            }
            // To allow other drag and drops throughout the app
            .hide(if: !SettingsViewModel.shared.showSettings, removeCompletely: true)
        }
    }
}
