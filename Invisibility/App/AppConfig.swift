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
    static let sentry_dsn = "https://a345c7071f6f1c4adee0a33e5f359e9e@o4506922235592704.ingest.us.sentry.io/4506922241097728"
    static let posthog_api_key = "phc_aVzM8zKxuKj8BzbIDO7ByvmSH90WwB1vCZ1zPCZw9Y3"

    // static let invisibility_api_base = "https://cloak.i.inc"
    static let invisibility_api_base = "http://localhost:8000"
    // static let invisibility_api_base = "http://localhost:8080/3cdad38b-2438-4999-93b7-50e0f952542f"
    // docker run --rm -p 8080:8080/tcp tarampampam/webhook-tester serve
}
