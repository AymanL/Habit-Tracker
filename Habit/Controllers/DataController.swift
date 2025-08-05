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
        
        // Create root nodes for each tree
        let programmingRoot = SkillNode(context: viewContext, name: "Programming Skills", type: .goal, description: "Root node for Programming Skills")
        programmingRoot.tree = programmingTree
        
        let fitnessRoot = SkillNode(context: viewContext, name: "Fitness Journey", type: .goal, description: "Root node for Fitness Journey")
        fitnessRoot.tree = fitnessTree
        
        // Add nodes to programming tree under root
        let swiftNode = SkillNode(context: viewContext, name: "Learn Swift", type: .goal, description: "Master Swift programming language")
        let iosNode = SkillNode(context: viewContext, name: "Build iOS App", type: .activity, description: "Create your first iOS application")
        let dailyCodeNode = SkillNode(context: viewContext, name: "Daily Coding", type: .habitLinked, description: "Practice coding daily")
        let advancedSwiftNode = SkillNode(context: viewContext, name: "Advanced Swift", type: .goal, description: "Learn advanced Swift concepts")
        let uiKitNode = SkillNode(context: viewContext, name: "Learn UIKit", type: .activity, description: "Master iOS UI development")
        
        swiftNode.tree = programmingTree
        iosNode.tree = programmingTree
        dailyCodeNode.tree = programmingTree
        advancedSwiftNode.tree = programmingTree
        uiKitNode.tree = programmingTree
        
        // Set up parent-child relationships under root
        programmingRoot.addChild(swiftNode) // Swift is child of Programming Skills root
        swiftNode.addChild(iosNode) // iOS is child of Swift
        swiftNode.addChild(dailyCodeNode) // Daily Coding is child of Swift
        swiftNode.addChild(advancedSwiftNode) // Advanced Swift is child of Swift
        iosNode.addChild(uiKitNode) // UIKit is child of iOS App
        
        // Add nodes to fitness tree under root
        let workoutNode = SkillNode(context: viewContext, name: "Start Working Out", type: .goal, description: "Begin your fitness journey")
        let runNode = SkillNode(context: viewContext, name: "Run 5K", type: .activity, description: "Complete a 5K run")
        let dailyExerciseNode = SkillNode(context: viewContext, name: "Daily Exercise", type: .habitLinked, description: "Exercise every day")
        let strengthNode = SkillNode(context: viewContext, name: "Strength Training", type: .activity, description: "Build muscle and strength")
        
        workoutNode.tree = fitnessTree
        runNode.tree = fitnessTree
        dailyExerciseNode.tree = fitnessTree
        strengthNode.tree = fitnessTree
        
        // Set up parent-child relationships under root
        fitnessRoot.addChild(workoutNode) // Workout is child of Fitness Journey root
        workoutNode.addChild(runNode) // Run 5K is child of Workout
        workoutNode.addChild(dailyExerciseNode) // Daily Exercise is child of Workout
        workoutNode.addChild(strengthNode) // Strength Training is child of Workout
        
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
    
    func createSkillTree(name: String, description: String = "", withSampleNodes: Bool = false) -> SkillTree {
        let tree = SkillTree(context: container.viewContext, name: name, description: description)
        
        // Create the root node with the same name as the tree
        let rootNode = SkillNode(context: container.viewContext, name: name, type: .goal, description: "Root node for \(name)")
        rootNode.tree = tree
        
        if withSampleNodes {
            // Ensure we have some habits to link to
            let existingHabits = getAllHabits()
            var habitsToUse = existingHabits
            
            // If no habits exist, create some sample habits
            if existingHabits.isEmpty {
                print("📝 No habits found, creating sample habits for linking...")
                for i in 0..<3 {
                    let habit = Habit(context: container.viewContext, title: "Sample Habit \(i + 1)", motivation: "A sample habit for testing", color: HabitColor.randomColor)
                    habitsToUse.append(habit)
                }
                save()
            }
            
            // Add some sample nodes under the root node
            let basicNode = createSkillNode(name: "Learn Basics", type: .goal, description: "Start with the fundamentals", in: tree)
            rootNode.addChild(basicNode)
            
            let milestoneNode = createSkillNode(name: "First Milestone", type: .activity, description: "Complete your first major goal", in: tree)
            rootNode.addChild(milestoneNode)
            
            let habitNode = createSkillNode(name: "Daily Practice", type: .habitLinked, description: "Link to an existing habit", in: tree)
            rootNode.addChild(habitNode)
            
            // Link habit node to first available habit
            if let firstHabit = habitsToUse.first {
                habitNode.linkToHabit(firstHabit)
            }
        }
        
        save()
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
        // Log the node and tree info before deletion
        let nodeName = node.name
        let treeName = node.tree?.name ?? "Unknown"
        let treeId = node.tree?.id ?? UUID()
        
        print("🗑️ About to delete skill node: \(nodeName) from tree: \(treeName)")
        print("🗑️ Tree ID: \(treeId)")
        
        // Delete the node (Core Data will handle the relationship automatically)
        container.viewContext.delete(node)
        
        // Save the context
        save()
        
        print("🗑️ Successfully deleted skill node: \(nodeName)")
        print("🗑️ Tree '\(treeName)' should still exist")
    }
    
    // MARK: - Parent-Child Node Management
    
    func addChildToParent(child: SkillNode, parent: SkillNode) {
        parent.addChild(child)
        save()
    }
    
    func removeChildFromParent(child: SkillNode) {
        child.parentNode?.removeChild(child)
        save()
    }
    
    func moveNodeToNewParent(node: SkillNode, newParent: SkillNode?) {
        // Remove from current parent
        node.parentNode?.removeChild(node)
        
        // Add to new parent (or make root if nil)
        if let newParent = newParent {
            newParent.addChild(node)
        }
        
        save()
    }
    
    func createChildNode(name: String, type: SkillNodeType, parent: SkillNode, description: String = "") -> SkillNode {
        let child = SkillNode(context: container.viewContext, name: name, type: type, description: description)
        child.tree = parent.tree
        parent.addChild(child)
        save()
        return child
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
    
    func debugCoreDataState() {
        print("=== DEBUG: Core Data State ===")
        print("Context has changes: \(container.viewContext.hasChanges)")
        
        // Check for any deleted objects
        let deletedObjects = container.viewContext.deletedObjects
        if !deletedObjects.isEmpty {
            print("⚠️ Deleted objects in context:")
            for obj in deletedObjects {
                print("   - \(obj)")
            }
        }
        
        // Check for any inserted objects
        let insertedObjects = container.viewContext.insertedObjects
        if !insertedObjects.isEmpty {
            print("➕ Inserted objects in context:")
            for obj in insertedObjects {
                print("   - \(obj)")
            }
        }
        
        // Check for any updated objects
        let updatedObjects = container.viewContext.updatedObjects
        if !updatedObjects.isEmpty {
            print("🔄 Updated objects in context:")
            for obj in updatedObjects {
                print("   - \(obj)")
            }
        }
    }
    
    func debugSkillNode(_ node: SkillNode) {
        print("=== DEBUG: Skill Node ===")
        print("Name: \(node.name)")
        print("Deleted: \(node.isDeleted)")
        print("Has Changes: \(node.hasChanges)")
        print("Object ID: \(node.objectID.uriRepresentation().absoluteString)")
        print("Context: \(node.managedObjectContext != nil)")
        
        if let tree = node.tree {
            print("Tree: \(tree.name)")
        } else {
            print("Tree: nil")
        }
        
        if let habit = node.habit {
            print("Habit: \(habit.title)")
        } else {
            print("Habit: nil")
        }
    }
    
    func createTestSkillTree() {
        let tree = createSkillTree(name: "Debug Skill Tree", description: "A test skill tree for debugging")
        
        _ = createSkillNode(name: "Learn Swift Basics", type: .goal, description: "Complete Swift fundamentals", in: tree)
        _ = createSkillNode(name: "Build First App", type: .activity, description: "Create your first iOS app", in: tree)
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

