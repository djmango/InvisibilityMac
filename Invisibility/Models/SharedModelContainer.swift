//
//  SharedModelContainer.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/16/24.
//

import Foundation
import SwiftData

class SharedModelContainer {
    static var shared: SharedModelContainer!

    var modelContainer: ModelContainer
    var mainContext: ModelContext

    @MainActor
    init() {
        let schema = Schema([Message.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            mainContext = modelContainer.mainContext
            mainContext.autosaveEnabled = true
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
