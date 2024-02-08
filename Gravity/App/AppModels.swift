//
//  AppModels.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/26/24.
//

import Foundation

let gravityHomeDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gravity")

struct ModelInfo {
    let name: String
    let url: URL
    let hash: String
    let localURL: URL
}

enum ModelRepository {
    static let WHISPER_SMALL = ModelInfo(
        name: "Whisper Small",
        url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin?download=true")!,
        hash: "ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb",
        localURL: gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("whisper")
            .appendingPathComponent("small.bin")
    )
    static let MISTRAL_7B_V2_Q4 = ModelInfo(
        name: "Mistral-7B",
        url: URL(string: "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf?download=true")!,
        hash: "3e0039fd0273fcbebb49228943b17831aadd55cbcbf56f0af00499be2040ccf9",
        localURL: gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("mistral")
            .appendingPathComponent("mistral-7b-instruct-v0.2.Q4_K_M.gguf")
    )
}
