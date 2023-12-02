import SwiftData

extension ModelContext {
    func saveChanges() throws {
        if self.hasChanges {
            try self.save()
        }
    }
}
