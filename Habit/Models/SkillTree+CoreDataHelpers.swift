import Foundation
import CoreData

extension SkillTree {
    // MARK: - Convenience Properties
    
    public var id: UUID {
        get { id_ ?? UUID() }
        set { id_ = newValue }
    }
    
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }
    
    var treeDescription: String {
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
    
    var nodes: [SkillNode] {
        get { nodes_?.allObjects as? [SkillNode] ?? [] }
        set { nodes_ = NSSet(array: newValue) }
    }
    
    // MARK: - Computed Properties
    
    var completionPercentage: Double {
        guard !nodes.isEmpty else { return 0.0 }
        let completedCount = nodes.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(nodes.count)
    }
    
    var completedNodesCount: Int {
        nodes.filter { $0.isCompleted }.count
    }
    
    var totalNodesCount: Int {
        nodes.count
    }
    
    // MARK: - Initialization
    
    convenience init(context: NSManagedObjectContext, name: String, description: String = "") {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.treeDescription = description
        self.creationDate = Date()
        
        // Set initial order to be the last in the list
        let request: NSFetchRequest<SkillTree> = SkillTree.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SkillTree.order_, ascending: false)]
        request.fetchLimit = 1
        
        if let lastTree = try? context.fetch(request).first {
            self.order_ = Int64(lastTree.order_) + 1
        } else {
            self.order_ = 0
        }
        
        print("🌳 Created SkillTree: \(name)")
    }
    
    // MARK: - Example Data
    
    static var example: SkillTree {
        let context = DataController.preview.container.viewContext
        let tree = SkillTree(context: context, name: "Example Skill Tree", description: "A sample skill tree for testing")
        
        // Add some example nodes
        let node1 = SkillNode(context: context, name: "Learn Swift", type: .goal)
        let node2 = SkillNode(context: context, name: "Build iOS App", type: .activity)
        let node3 = SkillNode(context: context, name: "Daily Practice", type: .habitLinked)
        
        node1.tree = tree
        node2.tree = tree
        node3.tree = tree
        
        return tree
    }
} 