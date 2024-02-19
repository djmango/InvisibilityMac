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
