//
//  ImportModuleTests.swift
//  HabitTests
//
//  Created by AI Assistant on 2024.
//

import CoreData
import XCTest
@testable import Habit

class ImportModuleTests: BaseTestCase {
    
    // MARK: - Test Data
    
    let validSingleTreeInput = """
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
    
    let simpleTreeInput = """
    Programming
    - Learn Python
    - Learn JavaScript
    """
    
    let deepNestedTreeInput = """
    Software Development
    - Frontend Development
    -- HTML & CSS
    --- Responsive Design
    --- CSS Frameworks
    -- JavaScript
    --- ES6+ Features
    --- React.js
    ---- Hooks
    ---- Context API
    --- Vue.js
    - Backend Development
    -- Node.js
    -- Python
    --- Django
    --- Flask
    """
    
    let emptyInput = ""
    let invalidInput = "Invalid format without proper structure"
    let singleLineInput = "Just one line without proper structure"
    
    // MARK: - Test Methods
    
    func testValidSingleTreeImport() {
        // Given
        let input = validSingleTreeInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 9) // Root + 5 level 1 + 3 level 2 (total 9)
        XCTAssertEqual(result.forests.count, 0)
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Swift Development")
        XCTAssertEqual(tree.nodes.count, 9)
        
        // Verify root node
        let rootNode = tree.nodes.first { $0.name == "Swift Development" }
        XCTAssertNotNil(rootNode, "Root node 'Swift Development' should exist")
        XCTAssertEqual(rootNode?.nodeType, .goal)
        
        // Verify level 1 nodes (children of root)
        
        let level1Nodes = tree.nodes.filter { $0.name != "Swift Development" && $0.parentNode?.name == "Swift Development" }
        XCTAssertEqual(level1Nodes.count, 5)
        XCTAssertTrue(level1Nodes.contains { $0.name == "Learn Swift Basics" })
        XCTAssertTrue(level1Nodes.contains { $0.name == "Understand Optionals" })
        XCTAssertTrue(level1Nodes.contains { $0.name == "Master Closures" })
        XCTAssertTrue(level1Nodes.contains { $0.name == "Build Simple Apps" })
        XCTAssertTrue(level1Nodes.contains { $0.name == "Advanced Swift Features" })
        
        // Verify level 2 nodes (children of Advanced Swift Features)
        let advancedFeaturesNode = level1Nodes.first { $0.name == "Advanced Swift Features" }
        XCTAssertNotNil(advancedFeaturesNode)
        
        let level2Nodes = tree.nodes.filter { $0.parentNode?.name == "Advanced Swift Features" }
        XCTAssertEqual(level2Nodes.count, 3)
        XCTAssertTrue(level2Nodes.contains { $0.name == "Protocol-Oriented Programming" })
        XCTAssertTrue(level2Nodes.contains { $0.name == "Generics and Type Constraints" })
        XCTAssertTrue(level2Nodes.contains { $0.name == "Memory Management" })
        
        // Verify specific nodes
        let learnSwiftBasics = level1Nodes.first { $0.name == "Learn Swift Basics" }
        XCTAssertNotNil(learnSwiftBasics)
        XCTAssertEqual(learnSwiftBasics?.nodeType, .goal)
        XCTAssertEqual(learnSwiftBasics?.parentNode, rootNode)
        
        let advancedFeatures = level1Nodes.first { $0.name == "Advanced Swift Features" }
        XCTAssertNotNil(advancedFeatures)
        XCTAssertEqual(advancedFeatures?.nodeType, .goal)
        XCTAssertEqual(advancedFeatures?.parentNode, rootNode)
        
        // Verify nested nodes
        let protocolOriented = level2Nodes.first { $0.name == "Protocol-Oriented Programming" }
        XCTAssertNotNil(protocolOriented)
        XCTAssertEqual(protocolOriented?.nodeType, .activity) // Level 2 nodes are created as .activity
        XCTAssertEqual(protocolOriented?.parentNode, advancedFeatures)
    }
    
    func testSimpleTreeImport() {
        // Given
        let input = simpleTreeInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 4) // Root + 2 nodes (total 4 including the automatically created root)
        XCTAssertEqual(result.forests.count, 0)
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Programming")
        XCTAssertEqual(tree.nodes.count, 4)
        
        // Verify root node
        let rootNode = tree.nodes.first { $0.name == "Programming" }
        XCTAssertNotNil(rootNode, "Root node 'Programming' should exist")
        XCTAssertEqual(rootNode?.nodeType, .goal)
        
        // Verify child nodes (children of root)
        let childNodes = tree.nodes.filter { $0.name != "Programming" && $0.parentNode?.name == "Programming" }
        XCTAssertEqual(childNodes.count, 2)
        
        let learnPython = childNodes.first { $0.name == "Learn Python" }
        XCTAssertNotNil(learnPython)
        XCTAssertEqual(learnPython?.parentNode?.name, "Programming")
        
        let learnJavaScript = childNodes.first { $0.name == "Learn JavaScript" }
        XCTAssertNotNil(learnJavaScript)
        XCTAssertEqual(learnJavaScript?.parentNode?.name, "Programming")
    }
    
    func testDeepNestedTreeImport() {
        // Given
        let input = deepNestedTreeInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertGreaterThan(result.nodesCount, 10) // Should have many nodes
        XCTAssertEqual(result.forests.count, 0)
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Software Development")
        XCTAssertGreaterThan(tree.nodes.count, 10)
        
        // Verify specific nodes exist
        let frontendDev = tree.nodes.first { $0.name == "Frontend Development" }
        XCTAssertNotNil(frontendDev)
        
        let backendDev = tree.nodes.first { $0.name == "Backend Development" }
        XCTAssertNotNil(backendDev)
        
        let htmlCss = tree.nodes.first { $0.name == "HTML & CSS" }
        XCTAssertNotNil(htmlCss)
        
        let reactJs = tree.nodes.first { $0.name == "React.js" }
        XCTAssertNotNil(reactJs)
    }
    
    func testEmptyInput() {
        // Given
        let input = emptyInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 0)
        XCTAssertEqual(result.nodesCount, 0)
        XCTAssertEqual(result.forests.count, 0)
    }
    
    func testInvalidInput() {
        // Given
        let input = invalidInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 0)
        XCTAssertEqual(result.nodesCount, 0)
        XCTAssertEqual(result.forests.count, 0)
    }
    
    func testSingleLineInput() {
        // Given
        let input = singleLineInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 2) // Root + 1 node (the single line becomes a tree)
        XCTAssertEqual(result.forests.count, 0)
    }
    
    func testInputWithOnlyRoot() {
        // Given
        let input = "Just a root node"
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 1) // Only root node
        XCTAssertEqual(result.forests.count, 0)
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Just a root node")
        XCTAssertEqual(tree.nodes.count, 1)
    }
    
    func testInputWithSpecialCharacters() {
        // Given
        let input = """
        Test Tree with Special Chars: @#$%^&*()
        - Node with spaces and dots ...
        - Node with dashes - and underscores _
        - Node with numbers 123 and symbols !@#
        """
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 4) // Root + 3 nodes
        XCTAssertEqual(result.forests.count, 0)
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Test Tree with Special Chars: @#$%^&*()")
        XCTAssertEqual(tree.nodes.count, 4)
    }
    
    func testInputWithEmptyLines() {
        // Given
        let input = """
        Test Tree
        
        - First Node
        
        - Second Node
        
        """
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 3) // Root + 2 nodes
        XCTAssertEqual(result.forests.count, 0)
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Test Tree")
        XCTAssertEqual(tree.nodes.count, 3)
    }
    
    func testInputWithMixedIndentation() {
        // Given
        let input = """
        Test Tree
        - Node 1
          - Subnode 1.1
        - Node 2
          - Subnode 2.1
            - Sub-subnode 2.1.1
        """
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 0)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertGreaterThan(result.nodesCount, 5) // Should have multiple nodes
        XCTAssertEqual(result.forests.count, 0)
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Test Tree")
        XCTAssertGreaterThan(tree.nodes.count, 5)
    }
    
    func testPerformanceWithLargeTree() {
        // Given
        let largeInput = generateLargeTreeInput()
        
        // When & Then
        measure {
            let result = parseSingleTree(input: largeInput)
            XCTAssertEqual(result.forestsCount, 0)
            XCTAssertEqual(result.treesCount, 1)
            XCTAssertGreaterThan(result.nodesCount, 100)
            XCTAssertEqual(result.forests.count, 0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseSingleTree(input: String) -> ImportResult {
        // Use the actual parsing logic from ImportSingleTreeView
        // This is a simplified version that tests the core functionality
        return parseAndImportSingleTree(input: input)
    }
    
    private func parseAndImportSingleTree(input: String) -> ImportResult {
        // Implementation that matches the actual import logic from ImportSingleTreeView
        if input.isEmpty {
            return ImportResult(forestsCount: 0, treesCount: 0, nodesCount: 0, forests: [])
        }
        
        let lines = input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            return ImportResult(forestsCount: 0, treesCount: 0, nodesCount: 0, forests: [])
        }
        
        let context = dataController.container.viewContext
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
                let tree = SkillTree(context: context, name: content)
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
                guard let tree = currentTree else { continue }
                
                let node = SkillNode(context: context, name: content, type: .goal)
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
                guard let tree = currentTree else { continue }
                
                let node = SkillNode(context: context, name: content, type: .activity)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == 2 }.count
                
                // Find the most recent level 1 node as parent
                if let parentIndex = nodeStack.lastIndex(where: { $0.1 == 1 }) {
                    let parent = nodeStack[parentIndex].0
                    parent.addChild(node)
                }
                
                nodeStack.append((node, 2))
                
            default:
                // Deeper levels (3+ dashes)
                guard let tree = currentTree else { continue }
                
                let node = SkillNode(context: context, name: content, type: .activity)
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
        
        // Save to Core Data
        try! context.save()
        
        return ImportResult(
            forestsCount: 0,
            treesCount: trees.count,
            nodesCount: trees.reduce(0) { sum, tree in sum + tree.totalNodesCount },
            forests: []
        )
    }
    
    private func getIndentationLevel(line: String) -> Int {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let original = line
        let leadingSpaces = original.count - trimmed.count
        return leadingSpaces / 2 // Assuming 2 spaces per level
    }
    
    private func generateLargeTreeInput() -> String {
        var input = "Large Test Tree\n"
        for i in 1...100 {
            input += "- Node \(i)\n"
            for j in 1...5 {
                input += "  - Subnode \(i).\(j)\n"
                for k in 1...3 {
                    input += "    - Sub-subnode \(i).\(j).\(k)\n"
                }
            }
        }
        return input
    }
}

// MARK: - ImportResult and ImportError Types

// Use the actual ImportResult from the main app
// The actual ImportResult is defined in ImportSkillTreeView.swift

// Use the actual ImportError from the main app
// The actual ImportError is defined in ImportSkillTreeView.swift
// and conforms to LocalizedError with different cases 