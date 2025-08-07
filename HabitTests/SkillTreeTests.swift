import CoreData
import XCTest
@testable import Habit

class SkillTreeTests: BaseTestCase {
    
    // MARK: - SkillTree Tests
    
    func testSkillTreeCreation() {
        let tree = SkillTree(context: managedObjectContext, name: "Test Tree", description: "A test skill tree")
        
        XCTAssertNotNil(tree.id)
        XCTAssertEqual(tree.name, "Test Tree")
        XCTAssertEqual(tree.description, "A test skill tree")
        XCTAssertFalse(tree.nodes.isEmpty) // Should be empty array, not nil
        XCTAssertEqual(tree.nodes.count, 0)
        XCTAssertEqual(tree.completionPercentage, 0.0)
        XCTAssertEqual(tree.completedNodesCount, 0)
        XCTAssertEqual(tree.totalNodesCount, 0)
    }
    
    func testSkillTreeDeletion() throws {
        let tree = SkillTree(context: managedObjectContext, name: "Test Tree")
        let initialCount = try managedObjectContext.count(for: SkillTree.fetchRequest())
        
        dataController.delete(tree)
        
        XCTAssertEqual(try managedObjectContext.count(for: SkillTree.fetchRequest()), initialCount)
    }
    
    func testSkillTreeOrdering() {
        let tree1 = SkillTree(context: managedObjectContext, name: "First Tree")
        let tree2 = SkillTree(context: managedObjectContext, name: "Second Tree")
        
        XCTAssertGreaterThan(tree2.order, tree1.order)
    }
    
    // MARK: - SkillNode Tests
    
    func testSkillNodeCreation() {
        let node = SkillNode(context: managedObjectContext, name: "Test Node", type: .goal)
        
        XCTAssertEqual(node.name, "Test Node")
        XCTAssertEqual(node.nodeType, .goal)
        XCTAssertFalse(node.isCompleted)
    }
    
    func testSkillNodeTypes() {
        let standaloneNode = SkillNode(context: managedObjectContext, name: "Goal", type: .goal)
        let activityNode = SkillNode(context: managedObjectContext, name: "Activity", type: .activity)
        let habitLinkedNode = SkillNode(context: managedObjectContext, name: "Habit Linked", type: .habitLinked)
        
        XCTAssertEqual(standaloneNode.nodeType, .goal)
        XCTAssertEqual(activityNode.nodeType, .activity)
        XCTAssertEqual(habitLinkedNode.nodeType, .habitLinked)
        
        XCTAssertEqual(standaloneNode.nodeType.displayName, "Goal")
        XCTAssertEqual(activityNode.nodeType.displayName, "Activity")
        XCTAssertEqual(habitLinkedNode.nodeType.displayName, "Habit Linked")
    }
    
    func testSkillNodeCompletion() {
        let node = SkillNode(context: managedObjectContext, name: "Test Node", type: .goal)
        
        XCTAssertFalse(node.isCompleted)
        XCTAssertNil(node.completionDate)
        XCTAssertTrue(node.canBeCompleted)
        
        node.complete()
        
        XCTAssertTrue(node.isCompleted)
        XCTAssertNotNil(node.completionDate)
        XCTAssertFalse(node.canBeCompleted)
    }
    
    func testSkillNodePosition() {
        let node = SkillNode(context: managedObjectContext, name: "Test Node", type: .goal)
        let testPosition = CGPoint(x: 100.0, y: 200.0)
        
        node.position = testPosition
        
        XCTAssertEqual(node.positionX, 100.0)
        XCTAssertEqual(node.positionY, 200.0)
        XCTAssertEqual(node.position, testPosition)
    }
    
    // MARK: - Relationship Tests
    
    func testSkillTreeNodeRelationship() {
        let tree = SkillTree(context: managedObjectContext, name: "Test Tree")
        let node = SkillNode(context: managedObjectContext, name: "Test Node", type: .goal)
        
        node.tree = tree
        
        XCTAssertEqual(tree.nodes.count, 1)
        XCTAssertEqual(tree.nodes.first, node)
        XCTAssertEqual(node.tree, tree)
    }
    
    func testSkillNodeHabitRelationship() {
        let habit = Habit(context: managedObjectContext, title: "Test Habit", motivation: "", color: .blue)
        let node = SkillNode(context: managedObjectContext, name: "Test Node", type: .habitLinked)
        
        node.linkToHabit(habit)
        
        XCTAssertEqual(node.habit, habit)
        XCTAssertTrue(node.isHabitLinked)
    }
    
    func testSkillNodeHabitUnlink() {
        let habit = Habit(context: managedObjectContext, title: "Test Habit", motivation: "", color: .blue)
        let node = SkillNode(context: managedObjectContext, name: "Test Node", type: .habitLinked)
        
        node.linkToHabit(habit)
        XCTAssertEqual(node.habit, habit)
        
        node.unlinkHabit()
        XCTAssertNil(node.habit)
        XCTAssertFalse(node.isHabitLinked)
    }
    
    // MARK: - DataController Tests
    
    func testCreateSkillTree() {
        let tree = dataController.createSkillTree(name: "Test Tree", description: "Test Description")
        
        XCTAssertEqual(tree.name, "Test Tree")
        XCTAssertEqual(tree.description, "Test Description")
        
        let trees = dataController.getAllSkillTrees()
        XCTAssertTrue(trees.contains { $0.id == tree.id })
    }
    
    func testCreateSkillNode() {
        let tree = dataController.createSkillTree(name: "Test Tree")
        let node = dataController.createSkillNode(name: "Test Node", type: .goal, description: "Test Description", in: tree)
        
        XCTAssertEqual(node.name, "Test Node")
        XCTAssertEqual(node.description, "Test Description")
        XCTAssertEqual(node.nodeType, .goal)
        XCTAssertEqual(node.tree, tree)
        
        let nodes = dataController.getAllSkillNodes()
        XCTAssertTrue(nodes.contains { $0.id == node.id })
    }
    
    func testFindSkillTree() throws {
        let tree = dataController.createSkillTree(name: "Test Tree")
        let foundTree = try dataController.findSkillTree(withId: tree.id)
        
        XCTAssertEqual(foundTree.id, tree.id)
        XCTAssertEqual(foundTree.name, tree.name)
    }
    
    func testFindSkillNode() throws {
        let tree = dataController.createSkillTree(name: "Test Tree")
        let node = dataController.createSkillNode(name: "Test Node", type: .goal, in: tree)
        let foundNode = try dataController.findSkillNode(withId: node.id)
        
        XCTAssertEqual(foundNode.id, node.id)
        XCTAssertEqual(foundNode.name, node.name)
    }
    
    // MARK: - Completion Tests
    
    func testSkillTreeCompletionPercentage() {
        let tree = SkillTree(context: managedObjectContext, name: "Test Tree")
        let node1 = SkillNode(context: managedObjectContext, name: "Node 1", type: .goal)
        let node2 = SkillNode(context: managedObjectContext, name: "Node 2", type: .goal)
        let node3 = SkillNode(context: managedObjectContext, name: "Node 3", type: .goal)
        
        node1.tree = tree
        node2.tree = tree
        node3.tree = tree
        
        XCTAssertEqual(tree.completionPercentage, 0.0)
        XCTAssertEqual(tree.completedNodesCount, 0)
        XCTAssertEqual(tree.totalNodesCount, 3)
        
        node1.complete()
        
        XCTAssertEqual(tree.completionPercentage, 1.0/3.0, accuracy: 0.001)
        XCTAssertEqual(tree.completedNodesCount, 1)
        XCTAssertEqual(tree.totalNodesCount, 3)
        
        node2.complete()
        node3.complete()
        
        XCTAssertEqual(tree.completionPercentage, 1.0, accuracy: 0.001)
        XCTAssertEqual(tree.completedNodesCount, 3)
        XCTAssertEqual(tree.totalNodesCount, 3)
    }
    
    // MARK: - Debug Tests
    
    func testDebugMethods() {
        // Create some test data
        let tree = dataController.createSkillTree(name: "Debug Tree")
        let _ = dataController.createSkillNode(name: "Debug Node", type: .goal, in: tree)
        
        // These should not crash and should print debug info
        dataController.debugAllEntities()
        dataController.debugSkillTrees()
        dataController.debugSkillNodes()
        dataController.createTestSkillTree()
    }
    
    // MARK: - Import Functionality Tests
    
    func testValidSingleTreeImport() throws {
        // Given
        let input = """
        Swift Development
        - Learn Swift Basics
        - Understand Optionals
        - Master Closures
        - Build Simple Apps
        - Advanced Swift Features
        -- Protocol-Oriented Programming
        -- Generics and Type Constraints
        -- Memory Management
        """
        
        // When
        let result = try parseAndImport(input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 9) // Root + 8 nodes
        
        // Verify tree was created
        let trees = try managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Swift Development")
        
        // Verify root node
        let rootNodes = tree.nodes.filter { $0.name == "Swift Development" }
        XCTAssertEqual(rootNodes.count, 1)
        XCTAssertEqual(rootNodes.first?.nodeType, .goal)
        
        // Verify level 1 nodes
        let level1Nodes = tree.nodes.filter { $0.name != "Swift Development" && $0.parentNode?.name == "Swift Development" }
        XCTAssertEqual(level1Nodes.count, 5)
        XCTAssertTrue(level1Nodes.contains { $0.name == "Learn Swift Basics" })
        XCTAssertTrue(level1Nodes.contains { $0.name == "Understand Optionals" })
        XCTAssertTrue(level1Nodes.contains { $0.name == "Master Closures" })
        XCTAssertTrue(level1Nodes.contains { $0.name == "Build Simple Apps" })
        XCTAssertTrue(level1Nodes.contains { $0.name == "Advanced Swift Features" })
        
        // Verify level 2 nodes
        let advancedFeaturesNode = level1Nodes.first { $0.name == "Advanced Swift Features" }
        XCTAssertNotNil(advancedFeaturesNode)
        
        let level2Nodes = tree.nodes.filter { $0.parentNode?.name == "Advanced Swift Features" }
        XCTAssertEqual(level2Nodes.count, 3)
        XCTAssertTrue(level2Nodes.contains { $0.name == "Protocol-Oriented Programming" })
        XCTAssertTrue(level2Nodes.contains { $0.name == "Generics and Type Constraints" })
        XCTAssertTrue(level2Nodes.contains { $0.name == "Memory Management" })
    }
    
    func testSimpleTreeImport() throws {
        // Given
        let input = """
        Programming
        - Learn Python
        - Learn JavaScript
        """
        
        // When
        let result = try parseAndImport(input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 3) // Root + 2 nodes
        
        let trees = try managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Programming")
        
        let childNodes = tree.nodes.filter { $0.name != "Programming" }
        XCTAssertEqual(childNodes.count, 2)
        XCTAssertTrue(childNodes.contains { $0.name == "Learn Python" })
        XCTAssertTrue(childNodes.contains { $0.name == "Learn JavaScript" })
    }
    
    func testEmptyInputThrowsError() throws {
        // Given
        let input = ""
        
        // When & Then
        XCTAssertThrowsError(try parseAndImport(input)) { error in
            if case ImportError.emptyFile = error as! ImportError {
                // Success - expected error
            } else {
                XCTFail("Expected emptyFile error, got: \(error)")
            }
        }
    }
    
    func testInvalidFormatThrowsError() throws {
        // Given
        let input = "Invalid format without proper structure"
        
        // When & Then
        XCTAssertThrowsError(try parseAndImport(input)) { error in
            if case ImportError.invalidFormat(let message) = error as! ImportError {
                XCTAssertTrue(message.contains("At least one line"))
            } else {
                XCTFail("Expected invalidFormat error, got: \(error)")
            }
        }
    }
    
    func testNodeWithoutTreeThrowsError() throws {
        // Given
        let input = """
        - Node without tree definition
        """
        
        // When & Then
        XCTAssertThrowsError(try parseAndImport(input)) { error in
            if case ImportError.noTreeDefined(let lineNumber) = error as! ImportError {
                XCTAssertEqual(lineNumber, 1)
            } else {
                XCTFail("Expected noTreeDefined error, got: \(error)")
            }
        }
    }
    
    func testInputWithEmptyLines() throws {
        // Given
        let input = """
        Test Tree
        
        - First Node
        
        - Second Node
        
        """
        
        // When
        let result = try parseAndImport(input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 3) // Root + 2 nodes
        
        let trees = try managedObjectContext.fetch(SkillTree.fetchRequest())
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Test Tree")
        
        let childNodes = tree.nodes.filter { $0.name != "Test Tree" }
        XCTAssertEqual(childNodes.count, 2)
        XCTAssertTrue(childNodes.contains { $0.name == "First Node" })
        XCTAssertTrue(childNodes.contains { $0.name == "Second Node" })
    }
    
    func testInputWithSpecialCharacters() throws {
        // Given
        let input = """
        Test Tree with Special Chars: @#$%^&*()
        - Node with spaces and dots ...
        - Node with dashes - and underscores _
        - Node with numbers 123 and symbols !@#
        """
        
        // When
        let result = try parseAndImport(input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 4) // Root + 3 nodes
        
        let trees = try managedObjectContext.fetch(SkillTree.fetchRequest())
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Test Tree with Special Chars: @#$%^&*()")
        
        let childNodes = tree.nodes.filter { $0.name != "Test Tree with Special Chars: @#$%^&*()" }
        XCTAssertEqual(childNodes.count, 3)
        XCTAssertTrue(childNodes.contains { $0.name == "Node with spaces and dots ..." })
        XCTAssertTrue(childNodes.contains { $0.name == "Node with dashes - and underscores _" })
        XCTAssertTrue(childNodes.contains { $0.name == "Node with numbers 123 and symbols !@#" })
    }
    
    // MARK: - Helper Methods
    
    private func parseAndImport(_ text: String) throws -> ImportResult {
        // This is a simplified version of the parseAndImport function for testing
        // It uses the same logic as ImportSingleTreeView but adapted for testing
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }
        
        guard lines.count >= 1 else {
            throw ImportError.invalidFormat("At least one line (tree name) is required")
        }
        
        var trees: [SkillTree] = []
        var currentTree: SkillTree?
        var nodeStack: [(SkillNode, Int)] = []
        
        for (index, line) in lines.enumerated() {
            let dashCount = line.prefix(while: { $0 == "-" }).count
            let content = String(line.dropFirst(dashCount)).trimmingCharacters(in: .whitespaces)
            
            guard !content.isEmpty else { continue }
            
            switch dashCount {
            case 0:
                // Tree name - create the tree (it automatically creates a root node)
                let tree = SkillTree(context: managedObjectContext, name: content)
                currentTree = tree
                
                // Find the automatically created root node
                let rootNode = tree.nodes.first { $0.name == content }
                if let root = rootNode {
                    nodeStack.removeAll()
                    nodeStack.append((root, 0)) // Root node is level 0
                }
                trees.append(tree)
                
            case 1:
                // Level 1 node (1 dash = level 1 in tree)
                guard let tree = currentTree else {
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                let node = SkillNode(context: managedObjectContext, name: content, type: .goal)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == 1 }.count
                
                // Find the root node (level 0) as parent
                if let rootIndex = nodeStack.lastIndex(where: { $0.1 == 0 }) {
                    let root = nodeStack[rootIndex].0
                    root.addChild(node)
                }
                
                nodeStack.append((node, 1))
                
            case 2:
                // Level 2 node (2 dashes = level 2 in tree)
                guard let tree = currentTree else {
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                let node = SkillNode(context: managedObjectContext, name: content, type: .activity)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == 2 }.count
                
                // Find the most recent level 1 node as parent
                if let parentIndex = nodeStack.lastIndex(where: { $0.1 == 1 }) {
                    let parent = nodeStack[parentIndex].0
                    parent.addChild(node)
                }
                
                nodeStack.append((node, 2))
                
            case 3:
                // Level 3 node (3 dashes = level 3 in tree)
                guard let tree = currentTree else {
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                let node = SkillNode(context: managedObjectContext, name: content, type: .activity)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == 3 }.count
                
                // Find the most recent level 2 node as parent
                if let parentIndex = nodeStack.lastIndex(where: { $0.1 == 2 }) {
                    let parent = nodeStack[parentIndex].0
                    parent.addChild(node)
                }
                
                nodeStack.append((node, 3))
                
            default:
                // Deeper levels (4+ dashes)
                guard let tree = currentTree else {
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                let node = SkillNode(context: managedObjectContext, name: content, type: .activity)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == dashCount }.count
                
                // Find the most recent node at the previous level as parent
                let parentLevel = dashCount - 1
                if let parentIndex = nodeStack.lastIndex(where: { $0.1 == parentLevel }) {
                    let parent = nodeStack[parentIndex].0
                    parent.addChild(node)
                }
                
                nodeStack.append((node, dashCount))
            }
        }
        
        try managedObjectContext.save()
        
        return ImportResult(
            forestsCount: 0,
            treesCount: trees.count,
            nodesCount: trees.reduce(0) { sum, tree in sum + tree.totalNodesCount },
            forests: []
        )
    }
} 