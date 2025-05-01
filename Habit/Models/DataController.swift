import CoreData

class DataController {
    let container = NSPersistentContainer(name: "Habit")

    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load store: \(error)")
            }
        }
    }

    func save() {
        print("DEBUG: Attempting to save context")
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
                print("DEBUG: Context saved successfully")
            } catch {
                print("DEBUG: Error saving context: \(error)")
            }
        } else {
            print("DEBUG: No changes to save")
        }
    }
} 