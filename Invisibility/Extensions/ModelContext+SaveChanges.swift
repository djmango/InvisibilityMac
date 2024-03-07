import SwiftData

extension ModelContext {
    func saveChanges() throws {
        if hasChanges {
            try save()
        }
    }
}
