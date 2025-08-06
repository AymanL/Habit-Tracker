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
    
    var forest: Forest? {
        get { forest_ }
        set { forest_ = newValue }
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
    
    // MARK: - Tree Structure
    
    var rootNodes: [SkillNode] {
        return nodes.filter { $0.parentNode == nil }.sorted { $0.order < $1.order }
    }
    
    func getNodesAtLevel(_ level: Int) -> [SkillNode] {
        return nodes.filter { $0.depth == level }.sorted { $0.order < $1.order }
    }
    
    func buildHierarchicalStructure() -> [SkillNode] {
        var result: [SkillNode] = []
        
        func addNodeAndChildren(_ node: SkillNode) {
            result.append(node)
            for child in node.childNodes.sorted(by: { $0.order < $1.order }) {
                addNodeAndChildren(child)
            }
        }
        
        for rootNode in rootNodes {
            addNodeAndChildren(rootNode)
        }
        
        return result
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
        
        // Create the root node with the same name as the tree
        let rootNode = SkillNode(context: context, name: name, type: .goal)
        rootNode.tree = self
        rootNode.order = 0
        
        print("🌳 Created SkillTree: \(name) with root node")
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