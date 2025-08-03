//
//  DataController.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

import CoreData
import UIKit

/// The `DataController` class is responsible for managing the Core Data stack and providing methods to interact with the data store.
///
/// It is implemented as a singleton using the static `shared` property, allowing access to the same instance across the application.
///
/// The `DataController` class provides the following functionalities:
/// - Loading the persistent stores for the Core Data stack.
/// - Saving changes made to the managed object context.
/// - Deleting objects from the managed object context.
/// - Creating a preview instance for testing and previewing purposes.
///
/// To use the `DataController`, simply access its shared instance using `DataController.shared`.
///
/// Example usage:
/// ```
/// let dataController = DataController.shared
/// dataController.save()
/// ```
class DataController: ObservableObject {
    
    /// The shared instance of the `DataController`.
    static let shared = DataController()
    
    /// The persistent container representing the Core Data stack.
    let container: NSPersistentContainer
    
    /// Initializes the `DataController` instance, either in memory (for temporary use such as testing and previewing), or on permanent storage (for use in regular app runs).
    ///
    /// - Parameter inMemory: A Boolean value indicating whether to use an in-memory database.
    ///                       Defaults to `false` which uses a persistent store on disk.
    ///
    /// - Note: When `inMemory` is `true`, a temporary, in-memory database is created. Data written to this database is destroyed after the app finishes running.
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Habit")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable lightweight migration
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            #if DEBUG
            if CommandLine.arguments.contains("enable-testing") {
                self.deleteAll()
                UIView.setAnimationsEnabled(false)
            }
            #endif
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// Saves Core Data context iff (if and only if) there are changes.
    ///
    /// This method checks if the managed object context has any changes and attempts to save them.
    /// - Note: Errors during the save operation are ignored, but this should be fine because the attributes are optional.
    func save() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }
    
    /// Deletes an object from the managed object context.
    ///
    /// - Parameter object: The `NSManagedObject` to be deleted.
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
    }
    
    func deleteAll() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Habit.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? container.viewContext.execute(batchDeleteRequest)
    }
    
    /// The preview instance of the `DataController`.
    ///
    /// This instance is created with an in-memory database and populated with example data for testing and previewing purposes.
    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        
        do {
            try dataController.createSampleData()
        } catch {
            fatalError("Fatal error creating preview: \(error.localizedDescription)")
        }
        
        return dataController
    }()
    
    
    /// Creates example habits for testing and previewing purposes.
    ///
    /// This method generates example `Habit` objects with sample data and saves them to the managed object context.
    ///
    /// - Throws: An NSError sent from calling save() on the NSManagedObjectContext.
    func createSampleData() throws {
        let viewContext = container.viewContext
        
        // Create sample habits
        for index in 0..<10 {
            let _ = Habit(context: viewContext, title: "Habit \(index)", motivation: "", color: HabitColor.randomColor)
        }
        
        // Create sample skill trees
        let programmingTree = SkillTree(context: viewContext, name: "Programming Skills", description: "Learn programming fundamentals")
        let fitnessTree = SkillTree(context: viewContext, name: "Fitness Journey", description: "Build healthy habits")
        
        // Add nodes to programming tree
        let swiftNode = SkillNode(context: viewContext, name: "Learn Swift", type: .standalone, description: "Master Swift programming language")
        let iosNode = SkillNode(context: viewContext, name: "Build iOS App", type: .oneShot, description: "Create your first iOS application")
        let dailyCodeNode = SkillNode(context: viewContext, name: "Daily Coding", type: .habitLinked, description: "Practice coding daily")
        
        swiftNode.tree = programmingTree
        iosNode.tree = programmingTree
        dailyCodeNode.tree = programmingTree
        
        // Add nodes to fitness tree
        let workoutNode = SkillNode(context: viewContext, name: "Start Working Out", type: .standalone, description: "Begin your fitness journey")
        let runNode = SkillNode(context: viewContext, name: "Run 5K", type: .oneShot, description: "Complete a 5K run")
        let dailyExerciseNode = SkillNode(context: viewContext, name: "Daily Exercise", type: .habitLinked, description: "Exercise every day")
        
        workoutNode.tree = fitnessTree
        runNode.tree = fitnessTree
        dailyExerciseNode.tree = fitnessTree
        
        // Link habit-linked nodes to existing habits
        let habits = try viewContext.fetch(Habit.fetchRequest())
        if let firstHabit = habits.first {
            dailyCodeNode.linkToHabit(firstHabit)
        }
        if habits.count > 1 {
            dailyExerciseNode.linkToHabit(habits[1])
        }
        
        try viewContext.save()
    }
    
}


extension DataController {
    
    func getAllHabits() -> [Habit] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        do {
            return try container.viewContext.fetch(request).sorted(by:  { $0.creationDate < $1.creationDate })
        } catch {
            print("Couldn't fetch all habits: \(error.localizedDescription)")
            return []
        }
    }
    
    func findHabit(withId id: UUID) throws -> Habit {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id_ = %@", id as CVarArg)
        
        do {
            guard let foundHabit = try container.viewContext.fetch(request).first else {
                throw Error.notFound
            }
            return foundHabit
        } catch {
            throw Error.notFound
        }
    }
    
    func getAllCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            return try container.viewContext.fetch(request).sorted(by: { $0.creationDate_ ?? Date() < $1.creationDate_ ?? Date() })
        } catch {
            print("Couldn't fetch all categories: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Skill Tree Methods
    
    func createSkillTree(name: String, description: String = "") -> SkillTree {
        let tree = SkillTree(context: container.viewContext, name: name, description: description)
        save()
        print("✅ Created skill tree: \(name)")
        return tree
    }
    
    func getAllSkillTrees() -> [SkillTree] {
        let request: NSFetchRequest<SkillTree> = SkillTree.fetchRequest()
        do {
            let trees = try container.viewContext.fetch(request)
            print("📊 Fetched \(trees.count) skill trees")
            return trees.sorted(by: { $0.creationDate < $1.creationDate })
        } catch {
            print("❌ Error fetching skill trees: \(error)")
            return []
        }
    }
    
    func findSkillTree(withId id: UUID) throws -> SkillTree {
        let request: NSFetchRequest<SkillTree> = SkillTree.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id_ = %@", id as CVarArg)
        
        do {
            guard let foundTree = try container.viewContext.fetch(request).first else {
                throw Error.notFound
            }
            return foundTree
        } catch {
            throw Error.notFound
        }
    }
    
    func deleteSkillTree(_ tree: SkillTree) {
        container.viewContext.delete(tree)
        save()
        print("🗑️ Deleted skill tree: \(tree.name)")
    }
    
    // MARK: - Skill Node Methods
    
    func createSkillNode(name: String, type: SkillNodeType, description: String = "", in tree: SkillTree) -> SkillNode {
        let node = SkillNode(context: container.viewContext, name: name, type: type, description: description)
        node.tree = tree
        save()
        print("✅ Created skill node: \(name) in tree: \(tree.name)")
        return node
    }
    
    func getAllSkillNodes() -> [SkillNode] {
        let request: NSFetchRequest<SkillNode> = SkillNode.fetchRequest()
        do {
            let nodes = try container.viewContext.fetch(request)
            print("📋 Fetched \(nodes.count) skill nodes")
            return nodes.sorted(by: { $0.creationDate < $1.creationDate })
        } catch {
            print("❌ Error fetching skill nodes: \(error)")
            return []
        }
    }
    
    func findSkillNode(withId id: UUID) throws -> SkillNode {
        let request: NSFetchRequest<SkillNode> = SkillNode.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id_ = %@", id as CVarArg)
        
        do {
            guard let foundNode = try container.viewContext.fetch(request).first else {
                throw Error.notFound
            }
            return foundNode
        } catch {
            throw Error.notFound
        }
    }
    
    func deleteSkillNode(_ node: SkillNode) {
        container.viewContext.delete(node)
        save()
        print("🗑️ Deleted skill node: \(node.name)")
    }
    
    // MARK: - Debug Methods
    
    func debugAllEntities() {
        print("=== DEBUG: All Entities ===")
        print("Habits: \(getAllHabits().count)")
        print("Categories: \(getAllCategories().count)")
        print("Skill Trees: \(getAllSkillTrees().count)")
        print("Skill Nodes: \(getAllSkillNodes().count)")
    }
    
    func debugSkillTrees() {
        let trees = getAllSkillTrees()
        print("🌳 Skill Trees (\(trees.count)):")
        for tree in trees {
            print("  - \(tree.name) (\(tree.nodes.count) nodes, \(Int(tree.completionPercentage * 100))% complete)")
        }
    }
    
    func debugSkillNodes() {
        let nodes = getAllSkillNodes()
        print("📋 Skill Nodes (\(nodes.count)):")
        for node in nodes {
            let status = node.isCompleted ? "✅" : "⭕"
            let habitInfo = node.isHabitLinked ? " (linked to: \(node.habit?.title ?? "unknown"))" : ""
            print("  \(status) \(node.name) (\(node.nodeType.displayName))\(habitInfo)")
        }
    }
    
    func createTestSkillTree() {
        let tree = createSkillTree(name: "Debug Skill Tree", description: "A test skill tree for debugging")
        
        _ = createSkillNode(name: "Learn Swift Basics", type: .standalone, description: "Complete Swift fundamentals", in: tree)
        _ = createSkillNode(name: "Build First App", type: .oneShot, description: "Create your first iOS app", in: tree)
        let node3 = createSkillNode(name: "Daily Coding Practice", type: .habitLinked, description: "Practice coding daily", in: tree)
        
        // Link the habit-linked node to an existing habit if available
        let habits = getAllHabits()
        if let firstHabit = habits.first {
            node3.linkToHabit(firstHabit)
        }
        
        save()
        print("✅ Created test skill tree with 3 nodes")
    }
    
}


extension URL {
    static func storeURL (for groupName: String, databaseName : String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName) else {
            fatalError("Could not create URL for \(groupName.lowercased())")
        }
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}

