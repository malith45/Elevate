import Foundation
import Combine
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "ElevateModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                let memoryStore = NSPersistentStoreDescription()
                memoryStore.type = NSInMemoryStoreType
                self.container.persistentStoreDescriptions = [memoryStore]
                self.container.loadPersistentStores { _, fallbackError in
                    if let fallbackError = fallbackError {
                        print("Failed to load Core Data store: \(error). Fallback failed: \(fallbackError)")
                    } else {
                        print("Failed to load Core Data store: \(error). Using in-memory store.")
                    }
                }
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
