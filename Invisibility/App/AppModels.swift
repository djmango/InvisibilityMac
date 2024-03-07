//
//  AppModels.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/26/24.
//

import Foundation

let invisibilityHomeDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".invisibility")

struct ModelInfo {
    let name: String
    let humanReadableName: String
    let url: URL
    let sha256: String
    let localURL: URL
}

enum ModelRepository {
    static let Whisper_Small = ModelInfo(
        name: "ggml-small-q5_1",
        humanReadableName: "Whisper Small",
        url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin?download=true")!,
        sha256: "ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb",
        localURL: invisibilityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("whisper")
            .appendingPathComponent("small.bin")
    )

    static let Whisper_Small_English = ModelInfo(
        name: "ggml-small.en-q5_1",
        humanReadableName: "Whisper Small (English)",
        url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en-q5_1.bin?download=true")!,
        sha256: "bfdff4894dcb76bbf647d56263ea2a96645423f1669176f4844a1bf8e478ad30",
        localURL: invisibilityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("whisper")
            .appendingPathComponent("small-en.bin")
    )

    static let Whisper_Medium = ModelInfo(
        name: "ggml-medium-q5_1",
        humanReadableName: "Whisper Medium",
        url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium-q5_0.bin?download=true")!,
        sha256: "19fea4b380c3a618ec4723c3eef2eb785ffba0d0538cf43f8f235e7b3b34220f",
        localURL: invisibilityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("whisper")
            .appendingPathComponent("medium.bin")
    )

    static let Mistral_7B = ModelInfo(
        name: "mistralai/Mistral-7B-v0.2",
        humanReadableName: "Mistral 7B",
        url: URL(string: "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf?download=true")!,
        sha256: "3e0039fd0273fcbebb49228943b17831aadd55cbcbf56f0af00499be2040ccf9",
        localURL: invisibilityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("mistral")
            .appendingPathComponent("mistral-7b-instruct-v0.2.Q4_K_M.gguf")
    )
}
