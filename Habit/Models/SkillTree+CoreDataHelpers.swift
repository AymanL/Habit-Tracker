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
    
    var currentLevel: Int {
        get { Int(currentLevel_) }
        set { currentLevel_ = Int64(newValue) }
    }
    
    var maxLevel: Int {
        get { Int(maxLevel_) }
        set { maxLevel_ = Int64(newValue) }
    }
    
    var nodes: [SkillNode] {
        get { nodes_?.allObjects as? [SkillNode] ?? [] }
        set { nodes_ = NSSet(array: newValue) }
    }
    
    // MARK: - Computed Properties
    
    private var nonRootNodes: [SkillNode] {
        return nodes.filter { $0.nodeType != .root }
    }

    var completionPercentage: Double {
        let progressNodes = nonRootNodes
        guard !progressNodes.isEmpty else { return 0.0 }
        let completedCount = progressNodes.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(progressNodes.count)
    }
    
    var completedNodesCount: Int {
        nonRootNodes.filter { $0.isCompleted }.count
    }
    
    var totalNodesCount: Int {
        nonRootNodes.count
    }
    
    // MARK: - Tree Structure
    
    var rootNodes: [SkillNode] {
        return nodes.filter { $0.parentNode == nil }.sorted { $0.order < $1.order }
    }
    
    func getNodesAtLevel(_ level: Int) -> [SkillNode] {
        return nodes.filter { $0.depth == level }.sorted { $0.order < $1.order }
    }
    
    // MARK: - Level Management
    
    func getNodesForLevel(_ level: Int) -> [SkillNode] {
        return nodes.filter { $0.level == level }.sorted { $0.order < $1.order }
    }
    
    func getRootNodeForLevel(_ level: Int) -> SkillNode? {
        return nodes.filter { $0.level == level && $0.nodeType == .root }.first
    }
    
    func ensureRootNodeExists(for level: Int) {
        // Check if root node already exists for this level
        if getRootNodeForLevel(level) != nil {
            return
        }
        
        // Create new root node for this level
        guard let context = managedObjectContext else { return }
        
        let rootNode = SkillNode(context: context, name: name, type: .root)
        rootNode.tree = self
        rootNode.level = level
        rootNode.order = 0
        
        print("🌳 Created root node for level \(level) in tree '\(name)'")
        
        // Update maxLevel if necessary
        if level > maxLevel {
            maxLevel = level
        }
    }
    
    func getUnlockedNodes() -> [SkillNode] {
        return nodes.filter { $0.level <= currentLevel }.sorted { $0.order < $1.order }
    }
    
    func getLockedNodes() -> [SkillNode] {
        return nodes.filter { $0.level > currentLevel }.sorted { $0.order < $1.order }
    }
    
    func isLevelUnlocked(_ level: Int) -> Bool {
        return level <= currentLevel
    }
    
    func canUnlockNextLevel() -> Bool {
        guard currentLevel < maxLevel else { return false }
        
        // Check if all nodes in current level are completed
        let currentLevelNodes = getNodesForLevel(currentLevel).filter { $0.nodeType != .root }
        return !currentLevelNodes.isEmpty && currentLevelNodes.allSatisfy { $0.isCompleted }
    }
    
    func unlockNextLevel() -> Bool {
        guard canUnlockNextLevel() else { return false }
        
        currentLevel += 1
        
        // Ensure there's a root node for the new current level
        ensureRootNodeExists(for: currentLevel)
        
        print("🔓 Unlocked level \(currentLevel) in tree '\(name)'")
        objectWillChange.send()
        return true
    }
    
    func getCurrentLevelProgress() -> (completed: Int, total: Int) {
        let levelNodes = getNodesForLevel(currentLevel).filter { $0.nodeType != .root }
        let completed = levelNodes.filter { $0.isCompleted }.count
        return (completed: completed, total: levelNodes.count)
    }
    
    func getLevelProgress(for level: Int) -> (completed: Int, total: Int) {
        let levelNodes = getNodesForLevel(level).filter { $0.nodeType != .root }
        let completed = levelNodes.filter { $0.isCompleted }.count
        return (completed: completed, total: levelNodes.count)
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
        self.currentLevel = 1
        self.maxLevel = 1
        
        // Set initial order to be the last in the list
        let request: NSFetchRequest<SkillTree> = SkillTree.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SkillTree.order_, ascending: false)]
        request.fetchLimit = 1
        
        if let lastTree = try? context.fetch(request).first {
            self.order_ = Int64(lastTree.order_) + 1
        } else {
            self.order_ = 0
        }
        
        // Create the root node for level 1
        ensureRootNodeExists(for: 1)
        
        print("🌳 Created SkillTree: \(name) with root node at level 1")
    }
    
    // MARK: - Completion Logic
    
    /// Automatically validates the root node when all non-root nodes are completed.
    /// If any non-root node becomes uncompleted, the root node is unvalidated.
    func updateRootCompletionState() {
        guard let root = rootNodes.first else { return }
        let progressNodes = nodes.filter { $0.nodeType != .root }
        guard !progressNodes.isEmpty else {
            if root.isCompleted { root.isCompleted = false }
            return
        }
        let shouldCompleteRoot = progressNodes.allSatisfy { $0.isCompleted }
        if root.isCompleted != shouldCompleteRoot {
            root.isCompleted = shouldCompleteRoot
        }
    }
    
    // MARK: - Example Data
    
    static var example: SkillTree {
        let context = DataController.preview.container.viewContext
        let tree = SkillTree(context: context, name: "Example Skill Tree", description: "A sample skill tree for testing")
        
        // Add some example nodes
        let node1 = SkillNode(context: context, name: "Learn Swift", type: .root)
        let node2 = SkillNode(context: context, name: "Build iOS App", type: .goal)
        let node3 = SkillNode(context: context, name: "Daily Practice", type: .activity)
        
        node1.tree = tree
        node2.tree = tree
        node3.tree = tree
        
        return tree
    }
} 