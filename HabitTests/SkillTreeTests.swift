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
        let rootNode = SkillNode(context: managedObjectContext, name: "Root", type: .root)
        let goalNode = SkillNode(context: managedObjectContext, name: "Goal", type: .goal)
        let activityNode = SkillNode(context: managedObjectContext, name: "Activity", type: .activity)
        let habitLinkedNode = SkillNode(context: managedObjectContext, name: "Habit Linked", type: .habitLinked)
        
        XCTAssertEqual(rootNode.nodeType, .root)
        XCTAssertEqual(goalNode.nodeType, .goal)
        XCTAssertEqual(activityNode.nodeType, .activity)
        XCTAssertEqual(habitLinkedNode.nodeType, .habitLinked)
        
        XCTAssertEqual(rootNode.nodeType.displayName, "Root")
        XCTAssertEqual(goalNode.nodeType.displayName, "Goal")
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
        let rootNode = tree.nodes.first { $0.name == "Swift Development" }
        XCTAssertNotNil(rootNode, "Root node 'Swift Development' should exist")
        XCTAssertEqual(rootNode?.nodeType, .root)
        
        // Verify level 1 nodes
        let level1Nodes = tree.nodes.filter { $0.name != "Swift Development" && $0.parentNode?.name == "Swift Development" }
        XCTAssertEqual(level1Nodes.count, 5)
        
        let learnSwiftBasicsNode = level1Nodes.first { $0.name == "Learn Swift Basics" }
        let understandOptionalsNode = level1Nodes.first { $0.name == "Understand Optionals" }
        let masterClosuresNode = level1Nodes.first { $0.name == "Master Closures" }
        let buildSimpleAppsNode = level1Nodes.first { $0.name == "Build Simple Apps" }
        let advancedFeaturesNode = level1Nodes.first { $0.name == "Advanced Swift Features" }
        
        XCTAssertNotNil(learnSwiftBasicsNode, "Learn Swift Basics node should exist")
        XCTAssertNotNil(understandOptionalsNode, "Understand Optionals node should exist")
        XCTAssertNotNil(masterClosuresNode, "Master Closures node should exist")
        XCTAssertNotNil(buildSimpleAppsNode, "Build Simple Apps node should exist")
        XCTAssertNotNil(advancedFeaturesNode, "Advanced Swift Features node should exist")
        
        // Verify all level 1 nodes have Swift Development as parent
        XCTAssertEqual(learnSwiftBasicsNode?.parentNode, rootNode, "Learn Swift Basics should have Swift Development as parent")
        XCTAssertEqual(understandOptionalsNode?.parentNode, rootNode, "Understand Optionals should have Swift Development as parent")
        XCTAssertEqual(masterClosuresNode?.parentNode, rootNode, "Master Closures should have Swift Development as parent")
        XCTAssertEqual(buildSimpleAppsNode?.parentNode, rootNode, "Build Simple Apps should have Swift Development as parent")
        XCTAssertEqual(advancedFeaturesNode?.parentNode, rootNode, "Advanced Swift Features should have Swift Development as parent")
        
        // Verify level 2 nodes
        let level2Nodes = tree.nodes.filter { $0.parentNode?.name == "Advanced Swift Features" }
        XCTAssertEqual(level2Nodes.count, 3)
        
        let protocolOrientedNode = level2Nodes.first { $0.name == "Protocol-Oriented Programming" }
        let genericsNode = level2Nodes.first { $0.name == "Generics and Type Constraints" }
        let memoryManagementNode = level2Nodes.first { $0.name == "Memory Management" }
        
        XCTAssertNotNil(protocolOrientedNode, "Protocol-Oriented Programming node should exist")
        XCTAssertNotNil(genericsNode, "Generics and Type Constraints node should exist")
        XCTAssertNotNil(memoryManagementNode, "Memory Management node should exist")
        
        // Verify all level 2 nodes have Advanced Swift Features as parent
        XCTAssertEqual(protocolOrientedNode?.parentNode, advancedFeaturesNode, "Protocol-Oriented Programming should have Advanced Swift Features as parent")
        XCTAssertEqual(genericsNode?.parentNode, advancedFeaturesNode, "Generics and Type Constraints should have Advanced Swift Features as parent")
        XCTAssertEqual(memoryManagementNode?.parentNode, advancedFeaturesNode, "Memory Management should have Advanced Swift Features as parent")
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
        
        // Find the root node (Programming)
        let rootNode = tree.nodes.first { $0.name == "Programming" }
        XCTAssertNotNil(rootNode, "Root node 'Programming' should exist")
        
        // Find child nodes and verify they have Programming as parent
        let learnPythonNode = tree.nodes.first { $0.name == "Learn Python" }
        let learnJavaScriptNode = tree.nodes.first { $0.name == "Learn JavaScript" }
        
        XCTAssertNotNil(learnPythonNode, "Learn Python node should exist")
        XCTAssertNotNil(learnJavaScriptNode, "Learn JavaScript node should exist")
        
        // Verify parent-child relationships
        XCTAssertEqual(learnPythonNode?.parentNode, rootNode, "Learn Python should have Programming as parent")
        XCTAssertEqual(learnJavaScriptNode?.parentNode, rootNode, "Learn JavaScript should have Programming as parent")
        
        // Verify the root node has these as children
        XCTAssertTrue(rootNode?.childNodes.contains(learnPythonNode!) ?? false, "Programming should have Learn Python as child")
        XCTAssertTrue(rootNode?.childNodes.contains(learnJavaScriptNode!) ?? false, "Programming should have Learn JavaScript as child")
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
        
        // Find the root node (Test Tree)
        let rootNode = tree.nodes.first { $0.name == "Test Tree" }
        XCTAssertNotNil(rootNode, "Root node 'Test Tree' should exist")
        
        // Find child nodes and verify they have Test Tree as parent
        let firstNode = tree.nodes.first { $0.name == "First Node" }
        let secondNode = tree.nodes.first { $0.name == "Second Node" }
        
        XCTAssertNotNil(firstNode, "First Node should exist")
        XCTAssertNotNil(secondNode, "Second Node should exist")
        
        // Verify parent-child relationships
        XCTAssertEqual(firstNode?.parentNode, rootNode, "First Node should have Test Tree as parent")
        XCTAssertEqual(secondNode?.parentNode, rootNode, "Second Node should have Test Tree as parent")
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
        
        // Find the root node (Test Tree with Special Chars)
        let rootNode = tree.nodes.first { $0.name == "Test Tree with Special Chars: @#$%^&*()" }
        XCTAssertNotNil(rootNode, "Root node should exist")
        
        // Find child nodes and verify they have the root as parent
        let nodeWithSpaces = tree.nodes.first { $0.name == "Node with spaces and dots ..." }
        let nodeWithDashes = tree.nodes.first { $0.name == "Node with dashes - and underscores _" }
        let nodeWithNumbers = tree.nodes.first { $0.name == "Node with numbers 123 and symbols !@#" }
        
        XCTAssertNotNil(nodeWithSpaces, "Node with spaces should exist")
        XCTAssertNotNil(nodeWithDashes, "Node with dashes should exist")
        XCTAssertNotNil(nodeWithNumbers, "Node with numbers should exist")
        
        // Verify parent-child relationships
        XCTAssertEqual(nodeWithSpaces?.parentNode, rootNode, "Node with spaces should have root as parent")
        XCTAssertEqual(nodeWithDashes?.parentNode, rootNode, "Node with dashes should have root as parent")
        XCTAssertEqual(nodeWithNumbers?.parentNode, rootNode, "Node with numbers should have root as parent")
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
        
        // Require minimum content for a valid single-tree import: at least one line is okay here
        
        var trees: [SkillTree] = []
        var currentTree: SkillTree?
        var nodeStack: [(SkillNode, Int)] = []
        
        func parseTaggedContent(_ raw: String, defaultType: SkillNodeType) -> (String, SkillNodeType) {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("["), let close = trimmed.firstIndex(of: "]") else {
                return (trimmed, defaultType)
            }
            let tagRange = trimmed.index(after: trimmed.startIndex)..<close
            let tag = String(trimmed[tagRange]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let remainder = trimmed.index(after: close)..<trimmed.endIndex
            let name = String(trimmed[remainder]).trimmingCharacters(in: .whitespaces)
            let mapping: [String: SkillNodeType] = [
                "goal": .goal,
                "g": .goal,
                "action": .activity,
                "activity": .activity,
                "a": .activity,
                "boss": .boss,
                "boss fight": .boss,
                "bossfight": .boss
            ]
            let type = mapping[tag] ?? defaultType
            return (name.isEmpty ? trimmed : name, type)
        }

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
                    if lines.count == 1 {
                        let defaultChild = SkillNode(context: managedObjectContext, name: "First Goal", type: .goal)
                        defaultChild.tree = tree
                        defaultChild.order = 0
                        root.addChild(defaultChild)
                    }
                }
                trees.append(tree)
                
            case 1:
                // Level 1 node (1 dash = level 1 in tree)
                guard let tree = currentTree else {
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                let (parsedName1, parsedType1) = parseTaggedContent(content, defaultType: .goal)
                let node = SkillNode(context: managedObjectContext, name: parsedName1, type: parsedType1)
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
                
                let (parsedName2, parsedType2) = parseTaggedContent(content, defaultType: .activity)
                let node = SkillNode(context: managedObjectContext, name: parsedName2, type: parsedType2)
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
                
                let (parsedName3, parsedType3) = parseTaggedContent(content, defaultType: .activity)
                let node = SkillNode(context: managedObjectContext, name: parsedName3, type: parsedType3)
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
                
                let (parsedNameN, parsedTypeN) = parseTaggedContent(content, defaultType: .activity)
                let node = SkillNode(context: managedObjectContext, name: parsedNameN, type: parsedTypeN)
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
            treesCount: trees.count,
            nodesCount: trees.reduce(0) { sum, tree in sum + tree.nodes.count },
            skillTrees: trees
        )
    }
} 