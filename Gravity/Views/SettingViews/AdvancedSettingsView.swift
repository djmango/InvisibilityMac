//
//  AdvancedSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @State private var selectedModel = "mistral:latest"
    @State private var systemInstruction = ""
    @State private var temperature: Double = 0.7
    @State private var maxContextLength: Int = 6000
    @State private var isEditingInstruction = false
    @State private var showingModelPicker = false

    // Models for picker, assuming these are your models
    let models = ["mistral:latest", "llava:latest"]

    var body: some View {
        VStack {
            Spacer()
            Form {
                Picker("Models:", selection: $selectedModel) {
                    ForEach(models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .bold()
                .pickerStyle(.radioGroup)

                Button(action: {
                    showingModelPicker.toggle()
                }) {
                    Image(systemName: "plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 10, height: 10)
                }
                .sheet(isPresented: $showingModelPicker) {
                    ModelPickerView(selectedModels: models)
                }
            }
            .frame(width: 550)
            .padding(.bottom, 10)

            // Divider()

            HStack {
                Text("System Instruction:").bold()
                Button("Edit System Instruction") {
                    isEditingInstruction.toggle()
                }
                .sheet(isPresented: $isEditingInstruction, content: {
                    // Custom view to edit the instruction
                    TextEditor(text: $systemInstruction)
                        .frame(minWidth: 300, minHeight: 200)
                })
            }

            HStack {
                Text("Temperature:").bold()
                Slider(value: $temperature, in: 0.0 ... 1.0, step: 0.1)
                    .frame(width: 200)
                Text("\(temperature, specifier: "%.1f")")
            }

            HStack {
                Text("Max Context Length:").bold()
                Stepper(value: $maxContextLength, in: 1000 ... 8000, step: 1000) {
                    Text("\(maxContextLength) Tokens")
                }
            }
            .padding(.bottom, 10)
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
