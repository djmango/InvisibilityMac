//
//  AdvancedSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @AppStorage("selectedModel") private var selectedModel = "mistral:latest"
    @AppStorage("systemInstruction") private var systemInstruction = ""
    @AppStorage("temperature") private var temperature: Double = 0.7
    @AppStorage("maxContextLength") private var maxContextLength: Double = 4000
    @AppStorage("onboardingViewed") private var onboardingViewed = false

    @State private var isEditingInstruction = false
    @State private var showingModelPicker = false

    // Models for picker, assuming these are your models
    let models: [String] = ["mistral:latest"]

    var body: some View {
        VStack {
            Spacer()

            // Form {
            //     Picker("Default Model:", selection: $selectedModel) {
            //         ForEach(models, id: \.self) { model in
            //             Text(model.name).tag(model.name)
            //         }
            //     }
            //     .bold()
            //     .pickerStyle(.radioGroup)

            //     Button(action: {
            //         showingModelPicker.toggle()
            //     }) {
            //         Image(systemName: "plus")
            //             .resizable()
            //             .aspectRatio(contentMode: .fit)
            //             .frame(width: 9, height: 9)
            //     }
            //     .sheet(isPresented: $showingModelPicker) {
            //         ModelPickerView(selectedModels: [selectedModel])
            //     }
            // }
            // .frame(width: 550)
            // .padding(.bottom, 10)

            // Divider()

            // HStack {
            //     Text("Default System Instruction:").bold()
            //     Button("Edit System Instruction") {
            //         isEditingInstruction.toggle()
            //     }
            //     .sheet(isPresented: $isEditingInstruction, content: {
            //         // Custom view to edit the instruction
            //         TextEditor(text: $systemInstruction)
            //             .frame(minWidth: 300, minHeight: 200)
            //     })
            // }

            HStack {
                Text("Model Temperature:").bold()
                Slider(value: $temperature, in: 0.0 ... 1.0, step: 0.1)
                    .frame(width: 200)
                Text("\(temperature, specifier: "%.1f")")
            }

            Spacer()

            HStack {
                Text("Model Context Length:").bold()
                Slider(value: $maxContextLength, in: 1000 ... 8000, step: 500)
                    .frame(width: 200)
                Text("\(maxContextLength, specifier: "%.0f") Tokens")
            }
            .padding(.bottom, 10)

            Spacer()

            Section {
                Button("Reset Onboarding") {
                    onboardingViewed = false
                }
                .bold()
            }

            Spacer()

            Section {
                Button("Reset All Settings") {
                    selectedModel = "mistral:latest"
                    systemInstruction = ""
                    temperature = 0.7
                    maxContextLength = 4000
                }
                .bold()
            }

            Spacer()

            Section {
                Button("Apply Settings") {
                    LLMManager.shared.load()
                }
                .bold()
            }

            Spacer()
        }
    }
}

// Example view for the model picker
struct ModelPickerView: View {
    let selectedModels: [String]
    // State variables and methods to handle model selection would go here

    var body: some View {
        // Your model picker UI implementation
        Text("Model Picker UI")
    }
}
