//
//  LLMTypes.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/21/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

struct APIModelResponse: Codable {
    let models: [APIModel]
}

struct APIModel: Codable {
    let model_name: String
    let display_name: String
    // Add other fields here if needed in the future, but we'll ignore them for now
}

struct LLMModel: Codable, Equatable, Hashable, Identifiable {
    let text: String
    let vision: String?
    let human_name: String

    // Equatable
    static func == (lhs: LLMModel, rhs: LLMModel) -> Bool {
        lhs.id == rhs.id
    }

    // Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(human_name)
    }

    // Identifiable
    var id: String {
        human_name
    }

    // From API Model
    static func fromAPIModel(_ apiModel: APIModel) -> LLMModel {
        LLMModel(text: apiModel.model_name, vision: apiModel.model_name, human_name: apiModel.display_name)
    }
}
