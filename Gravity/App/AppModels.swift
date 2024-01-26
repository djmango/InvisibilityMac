//
//  AppModels.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/26/24.
//

import Foundation

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
        localURL: DownloadManager.gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("whisper")
            .appendingPathComponent("small.bin")
    )
    static let MISTRAL_7B_V2_Q4 = ModelInfo(
        name: "Mistral 7B v2 Q4",
        url: URL(string: "https://huggingface.co/djmango/mistral-7b-v0.2-q4_0.gguf/resolve/main/mistral-7b-v0.2-q4_0.gguf?download=true")!,
        hash: "a1710fb85f2bd8e2c191bfc498211cdd469fe94a45920d19eaf28115844b6959",
        localURL: DownloadManager.gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("mistral")
            .appendingPathComponent("7b-v0.2-q4_0.gguf")
    )
}
