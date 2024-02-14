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
        localURL: gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("whisper")
            .appendingPathComponent("small.bin")
    )

    static let Whisper_Medium = ModelInfo(
        name: "ggml-medium-q5_1",
        humanReadableName: "Whisper Medium",
        url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium-q5_0.bin?download=true")!,
        sha256: "19fea4b380c3a618ec4723c3eef2eb785ffba0d0538cf43f8f235e7b3b34220f",
        localURL: gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("whisper")
            .appendingPathComponent("medium.bin")
    )

    static let Mistral_7B = ModelInfo(
        name: "mistralai/Mistral-7B-v0.2",
        humanReadableName: "Mistral 7B",
        url: URL(string: "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf?download=true")!,
        sha256: "3e0039fd0273fcbebb49228943b17831aadd55cbcbf56f0af00499be2040ccf9",
        localURL: gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("mistral")
            .appendingPathComponent("mistral-7b-instruct-v0.2.Q4_K_M.gguf")
    )

    static let Truthful_FusionNet_7Bx2_MoE = ModelInfo(
        name: "yunconglong/Truthful_DPO_TomGrc_FusionNet_7Bx2_MoE_13B",
        humanReadableName: "Truthful FusionNet 7Bx2 MoE",
        url: URL(string: "https://huggingface.co/Nan-Do/Truthful_DPO_TomGrc_FusionNet_7Bx2_MoE_13B-GGUF/resolve/main/Truthful_DPO_TomGrc_FusionNet_7Bx2_MoE_13B-Q5_0.gguf?download=true")!,
        sha256: "68658f47af9152e4770cdafc7f9d7e83942a4c8410525ba843542ab6ec5f2395",
        localURL: gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("truthful_fusionnet")
            .appendingPathComponent("Truthful_DPO_TomGrc_FusionNet_7Bx2_MoE_13B-Q5_0.gguf")
    )

    static let OpenHermes_2_5_Mistral_7B = ModelInfo(
        name: "teknium/OpenHermes-2.5-Mistral-7B",
        humanReadableName: "OpenHermes 2.5 Mistral 7B",
        url: URL(string: "https://huggingface.co/TheBloke/OpenHermes-2.5-Mistral-7B-GGUF/resolve/main/openhermes-2.5-mistral-7b.Q5_K_M.gguf?download=true")!,
        sha256: "61e9e801d9e60f61a4bf1cad3e29d975ab6866f027bcef51d1550f9cc7d2cca6",
        localURL: gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("openhermes")
            .appendingPathComponent("openhermes-2.5-mistral-7b.Q5_K_M.gguf")
    )
}
