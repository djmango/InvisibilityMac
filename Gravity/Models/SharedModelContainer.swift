//
//  SharedModelContainer.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/16/24.
//

import Foundation
import SwiftData

class SharedModelContainer {
    static var shared: SharedModelContainer!

    var modelContainer: ModelContainer
    var mainContext: ModelContext

    // @MainActor var mainContext: ModelContext {
    //     modelContainer.mainContext
    // }

    @MainActor
    init() {
        let schema = Schema([Chat.self, Message.self, OllamaModel.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            mainContext = modelContainer.mainContext
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
