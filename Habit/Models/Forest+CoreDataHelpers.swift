import Foundation
import CoreData

extension Forest {
    // MARK: - Convenience Properties
    
    public var id: UUID {
        get { id_ ?? UUID() }
        set { id_ = newValue }
    }
    
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }
    
    var forestDescription: String {
        get { description_ ?? "" }
        set { description_ = newValue }
    }
    
    var order: Int {
        get { Int(order_) }
        set { order_ = Int64(newValue) }
    }
    
    var creationDate: Date {
        get { creationDate_ ?? Date() }
        set { creationDate_ = newValue }
    }
    
    var trees: [SkillTree] {
        get { trees_?.allObjects as? [SkillTree] ?? [] }
        set { trees_ = NSSet(array: newValue) }
    }
    
    // MARK: - Computed Properties
    
    var completionPercentage: Double {
        guard !trees.isEmpty else { return 0.0 }
        let totalCompletion = trees.reduce(0.0) { sum, tree in
            sum + tree.completionPercentage
        }
        return totalCompletion / Double(trees.count)
    }
    
    var completedTreesCount: Int {
        trees.filter { $0.completionPercentage == 1.0 }.count
    }
    
    var totalTreesCount: Int {
        trees.count
    }
    
    var totalNodesCount: Int {
        trees.reduce(0) { sum, tree in
            sum + tree.totalNodesCount
        }
    }
    
    var completedNodesCount: Int {
        trees.reduce(0) { sum, tree in
            sum + tree.completedNodesCount
        }
    }
    
    // MARK: - Tree Management
    
    func addTree(_ tree: SkillTree) {
        tree.forest = self
        // Note: The actual relationship will be managed by Core Data
    }
    
    func removeTree(_ tree: SkillTree) {
        tree.forest = nil
    }
    
    func getTreesSortedByOrder() -> [SkillTree] {
        return trees.sorted { $0.order < $1.order }
    }
    
    // MARK: - Initialization
    
    convenience init(context: NSManagedObjectContext, name: String, description: String = "") {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.forestDescription = description
        self.creationDate = Date()
        
        // Set initial order to be the last in the list
        let request: NSFetchRequest<Forest> = Forest.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Forest.order_, ascending: false)]
        request.fetchLimit = 1
        
        if let lastForest = try? context.fetch(request).first {
            self.order_ = Int64(lastForest.order_) + 1
        } else {
            self.order_ = 0
        }
        
        print("🌲 Created Forest: \(name)")
    }
    
    // MARK: - Example Data
    
    static var example: Forest {
        let context = DataController.preview.container.viewContext
        let forest = Forest(context: context, name: "Example Forest", description: "A sample forest for testing")
        
        // Add some example trees
        let tree1 = SkillTree(context: context, name: "Programming Skills", description: "Software development skills")
        let tree2 = SkillTree(context: context, name: "Fitness Goals", description: "Physical fitness objectives")
        
        tree1.forest = forest
        tree2.forest = forest
        
        return forest
    }
} 