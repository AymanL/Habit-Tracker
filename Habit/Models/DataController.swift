import CoreData

class DataController: ObservableObject {
    static let shared = DataController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "Habit")
        
        // Configure migration
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // Set the current model version
        if let modelURL = Bundle.main.url(forResource: "Habit", withExtension: "momd") {
            if let model = NSManagedObjectModel(contentsOf: modelURL) {
                container.managedObjectModel = model
            }
        }
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
                
                // If migration fails, try to delete the store and create a new one
                if let url = description.url {
                    do {
                        try FileManager.default.removeItem(at: url)
                        print("Deleted old store, will create new one on next launch")
                    } catch {
                        print("Failed to delete old store: \(error)")
                    }
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
} 