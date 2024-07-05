//
//  AppConfig.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/16/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SwiftUI

enum AppConfig {
    static let subsystem = "so.invisibility.app"

    static let snappy: Animation = .snappy(duration: 0.4)
    static let easeIn: Animation = .easeIn(duration: 0.2)
    static let easeOut: Animation = .easeOut(duration: 0.2)
    static let easeInOut: Animation = .easeInOut(duration: 0.2)
    static let posthog_api_key = "phc_aVzM8zKxuKj8BzbIDO7ByvmSH90WwB1vCZ1zPCZw9Y3"
    static let rollbar_key = "01fc4a7df060464191fa79bf3e6ecb0d"

    static let whats_new_version = "116" // Set to the version of the last "what's new" release
    static let whats_new_features: [WhatsNewFeature] = [ // Highlighted features for the last "what's new" release
        WhatsNewFeature(iconName: "memorychip.fill", iconColor: .blue, title: "Memories", description: "Now Invisibility learns your preferences as you chat and remembers them."),
        WhatsNewFeature(iconName: "person.fill.checkmark", iconColor: .green, title: "Tailored Responses", description: "The AI will tailor its responses to you based on your preferences."),
        WhatsNewFeature(iconName: "waveform", iconColor: .cyan, title: "Wow New", description: "Now Invisibility learns your preferences as you chat and remembers them."),
    ]

    static let invisibility_api_base = "https://cloak.i.inc"
    // static let invisibility_api_base = "http://localhost:8000"
    // static let invisibility_api_base = "http://localhost:8080/3cdad38b-2438-4999-93b7-50e0f952542f"
    // docker run --rm -p 8080:8080/tcp tarampampam/webhook-tester serve
}
