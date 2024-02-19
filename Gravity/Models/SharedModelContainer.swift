//
//  SharedModelContainer.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/16/24.
//

import Foundation
import SwiftData

// enum DatabaseVersion {
//     static let currentVersion = 2
// }

// func checkDatabaseVersionAndMigrateIfNeeded() {
//     let storedVersion = UserDefaults.standard.integer(forKey: "databaseVersion")

//     if storedVersion < DatabaseVersion.currentVersion {
//         // Perform migration logic here
//         migrateDatabase(from: storedVersion)

//         // Update the stored version to the current version after successful migration
//         UserDefaults.standard.set(DatabaseVersion.currentVersion, forKey: "databaseVersion")
//     }
// }

// func migrateDatabase(from oldVersion: Int) {
//     switch oldVersion {
//     case 0:
//         // Migrate from version 1 to 2
//         print("Migrating database from version 1 to 2...")
//         // Example: Update database schema, transform data, etc.
//         // Remember to handle failures and ensure data integrity.

//     // Add more cases as needed for future versions
//     default:
//         print("No migration needed or migration path not supported.")
//     }

//     print("Migration completed.")
// }

class SharedModelContainer {
    static var shared: SharedModelContainer!

    var modelContainer: ModelContainer
    var mainContext: ModelContext

    @MainActor
    init() {
        let schema = Schema([Chat.self, Message.self, Audio.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            mainContext = modelContainer.mainContext
            mainContext.autosaveEnabled = true
            // modelContainer.migrationPlan = { migration in
            //     // Perform migration logic here
            //     // Example: Update database schema, transform data, etc.
            //     // Remember to handle failures and ensure data integrity.
            // }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
