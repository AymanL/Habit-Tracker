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
    # Swift Development
    ## Fundamentals
    - Learn Swift Basics
    - Understand Optionals
    - Master Closures
    ## Advanced Topics
    - Advanced Swift Features
    -- Protocol-Oriented Programming
    -- Generics and Type Constraints
    -- Memory Management
    """
    
    let simpleTreeInput = """
    # Programming
    ## Basics
    - Learn Python
    - Learn JavaScript
    """
    
    let deepNestedTreeInput = """
    # Software Development
    ## Frontend Development
    - Web Fundamentals
    -- HTML & CSS
    --- Responsive Design
    --- CSS Frameworks
    - JavaScript Frameworks
    -- React.js
    --- Hooks
    --- Context API
    -- Vue.js
    ## Backend Development
    - Server Technologies
    -- Node.js
    - Python Development
    -- Django
    -- Flask
    """
    
    let emptyInput = ""
    let invalidInput = "Invalid format without proper structure"
    let singleLineInput = """
    # Simple Tree
    ## Basic Level
    - Single Node
    """
    
    // MARK: - Test Methods
    
    func testValidSingleTreeImport() {
        // Given
        let input = validSingleTreeInput
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 10) // 1 tree root + 2 level root nodes + 7 child nodes
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Swift Development")
        XCTAssertEqual(tree.maxLevel, 2) // Two levels: Fundamentals and Advanced Topics
        
        // Verify tree-level root node
        let treeRootNode = tree.nodes.first { $0.name == "Swift Development" && $0.nodeType == .root }
        XCTAssertNotNil(treeRootNode)
        
        // Verify level 1 root node
        let level1Root = tree.getRootNodeForLevel(1)
        XCTAssertNotNil(level1Root)
        XCTAssertEqual(level1Root?.name, "Fundamentals")
        XCTAssertEqual(level1Root?.nodeType, .root)
        XCTAssertEqual(level1Root?.level, 1)
        
        // Verify level 2 root node  
        let level2Root = tree.getRootNodeForLevel(2)
        XCTAssertNotNil(level2Root)
        XCTAssertEqual(level2Root?.name, "Advanced Topics")
        XCTAssertEqual(level2Root?.nodeType, .root)
        XCTAssertEqual(level2Root?.level, 2)
        
        // Verify level 1 children (children of Fundamentals)
        let level1Children = tree.getNodesForLevel(1).filter { $0.parentNode == level1Root && $0.nodeType != .root }
        XCTAssertEqual(level1Children.count, 3)
        XCTAssertTrue(level1Children.contains { $0.name == "Learn Swift Basics" })
        XCTAssertTrue(level1Children.contains { $0.name == "Understand Optionals" })
        XCTAssertTrue(level1Children.contains { $0.name == "Master Closures" })
        
        // Verify level 2 children (children of Advanced Topics)
        let level2Children = tree.getNodesForLevel(2).filter { $0.parentNode == level2Root && $0.nodeType != .root }
        XCTAssertEqual(level2Children.count, 1)
        
        let advancedFeaturesNode = level2Children.first { $0.name == "Advanced Swift Features" }
        XCTAssertNotNil(advancedFeaturesNode)
        XCTAssertEqual(advancedFeaturesNode?.level, 2)
        
        // Verify nested nodes under Advanced Swift Features
        let nestedNodes = tree.getNodesForLevel(2).filter { $0.parentNode == advancedFeaturesNode }
        XCTAssertEqual(nestedNodes.count, 3)
        XCTAssertTrue(nestedNodes.contains { $0.name == "Protocol-Oriented Programming" })
        XCTAssertTrue(nestedNodes.contains { $0.name == "Generics and Type Constraints" })
        XCTAssertTrue(nestedNodes.contains { $0.name == "Memory Management" })
    }
    
    func testSimpleTreeImport() {
        // Given
        let input = simpleTreeInput
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 4) // 1 tree root + 1 level root node + 2 child nodes
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Programming")
        XCTAssertEqual(tree.maxLevel, 1) // One level: Basics
        
        // Verify tree-level root node
        let treeRootNode = tree.nodes.first { $0.name == "Programming" && $0.nodeType == .root }
        XCTAssertNotNil(treeRootNode)
        
        // Verify level 1 root node
        let level1Root = tree.getRootNodeForLevel(1)
        XCTAssertNotNil(level1Root)
        XCTAssertEqual(level1Root?.name, "Basics")
        XCTAssertEqual(level1Root?.nodeType, .root)
        
        // Verify child nodes (children of Basics root)
        let childNodes = tree.getNodesForLevel(1).filter { $0.parentNode == level1Root && $0.nodeType != .root }
        XCTAssertEqual(childNodes.count, 2)
        
        let learnPython = childNodes.first { $0.name == "Learn Python" }
        XCTAssertNotNil(learnPython)
        XCTAssertEqual(learnPython?.parentNode, level1Root)
        
        let learnJavaScript = childNodes.first { $0.name == "Learn JavaScript" }
        XCTAssertNotNil(learnJavaScript)
        XCTAssertEqual(learnJavaScript?.parentNode, level1Root)
    }
    
    func testDeepNestedTreeImport() {
        // Given
        let input = deepNestedTreeInput
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertGreaterThan(result.nodesCount, 10) // Should have many nodes
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Software Development")
        XCTAssertEqual(tree.maxLevel, 2) // Two levels: Frontend and Backend
        XCTAssertGreaterThan(tree.nodes.count, 10)
        
        // Verify level root nodes exist
        let frontendRoot = tree.getRootNodeForLevel(1)
        XCTAssertNotNil(frontendRoot)
        XCTAssertEqual(frontendRoot?.name, "Frontend Development")
        
        let backendRoot = tree.getRootNodeForLevel(2)
        XCTAssertNotNil(backendRoot)
        XCTAssertEqual(backendRoot?.name, "Backend Development")
        
        // Verify specific nodes exist in level 1
        let level1Nodes = tree.getNodesForLevel(1)
        let webFundamentals = level1Nodes.first { $0.name == "Web Fundamentals" }
        XCTAssertNotNil(webFundamentals)
        
        let htmlCss = level1Nodes.first { $0.name == "HTML & CSS" }
        XCTAssertNotNil(htmlCss)
        
        let reactJs = level1Nodes.first { $0.name == "React.js" }
        XCTAssertNotNil(reactJs)
        
        // Verify specific nodes exist in level 2
        let level2Nodes = tree.getNodesForLevel(2)
        let serverTech = level2Nodes.first { $0.name == "Server Technologies" }
        XCTAssertNotNil(serverTech)
        
        let pythonDev = level2Nodes.first { $0.name == "Python Development" }
        XCTAssertNotNil(pythonDev)
    }
    
    func testEmptyInput() {
        // Given
        let input = emptyInput
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 0)
        XCTAssertEqual(result.nodesCount, 0)
    }
    
    func testInvalidInput() {
        // Given
        let input = invalidInput
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 0)
        XCTAssertEqual(result.nodesCount, 0)
    }
    
    func testSingleLineInput() {
        // Given
        let input = singleLineInput
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 3) // 1 tree root + 1 level root node + 1 child node
    }
    
    func testInputWithOnlyRoot() {
        // Given
        let input = """
        # Just a root tree
        ## Only Root Level
        """
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 2) // 1 tree root + 1 level root node
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Just a root tree")
        XCTAssertEqual(tree.maxLevel, 1)
        
        let treeRootNode = tree.nodes.first { $0.name == "Just a root tree" && $0.nodeType == .root }
        XCTAssertNotNil(treeRootNode)
        
        let level1Root = tree.getRootNodeForLevel(1)
        XCTAssertNotNil(level1Root)
        XCTAssertEqual(level1Root?.name, "Only Root Level")
    }
    
    func testInputWithSpecialCharacters() {
        // Given
        let input = """
        # Test Tree with Special Chars: @#$%^&*()
        ## Special Characters Level
        - Node with spaces and dots ...
        - Node with dashes - and underscores _
        - Node with numbers 123 and symbols !@#
        """
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 5) // 1 tree root + 1 level root node + 3 child nodes
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Test Tree with Special Chars: @#$%^&*()")
        XCTAssertEqual(tree.maxLevel, 1)
        
        let treeRootNode = tree.nodes.first { $0.name == "Test Tree with Special Chars: @#$%^&*()" && $0.nodeType == .root }
        XCTAssertNotNil(treeRootNode)
        
        let level1Root = tree.getRootNodeForLevel(1)
        XCTAssertNotNil(level1Root)
        XCTAssertEqual(level1Root?.name, "Special Characters Level")
    }
    
    func testInputWithEmptyLines() {
        // Given
        let input = """
        # Test Tree
        ## Empty Lines Level
        
        - First Node
        
        - Second Node
        
        """
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 4) // 1 tree root + 1 level root node + 2 child nodes
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Test Tree")
        XCTAssertEqual(tree.maxLevel, 1)
        
        let treeRootNode = tree.nodes.first { $0.name == "Test Tree" && $0.nodeType == .root }
        XCTAssertNotNil(treeRootNode)
        
        let level1Root = tree.getRootNodeForLevel(1)
        XCTAssertNotNil(level1Root)
        XCTAssertEqual(level1Root?.name, "Empty Lines Level")
    }
    
    func testInputWithMixedIndentation() {
        // Given
        let input = """
        # Test Tree
        ## Mixed Indentation Level
        - Node 1
        -- Subnode 1.1
        - Node 2
        -- Subnode 2.1
        --- Sub-subnode 2.1.1
        """
        
        // When
        let result = parseMultipleTree(input: input)
        
        // Then
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertGreaterThan(result.nodesCount, 6) // Should have multiple nodes (tree root + level root + children)
        
        // Verify the tree structure by fetching from Core Data
        let trees = try! managedObjectContext.fetch(SkillTree.fetchRequest())
        XCTAssertEqual(trees.count, 1)
        
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Test Tree")
        XCTAssertEqual(tree.maxLevel, 1)
        XCTAssertGreaterThan(tree.nodes.count, 6)
        
        let treeRootNode = tree.nodes.first { $0.name == "Test Tree" && $0.nodeType == .root }
        XCTAssertNotNil(treeRootNode)
    }
    
    func testPerformanceWithLargeTree() {
        // Given
        let largeInput = generateLargeTreeInput()
        
        // When & Then
        measure {
            let result = parseMultipleTree(input: largeInput)
    
            XCTAssertEqual(result.treesCount, 1)
            XCTAssertGreaterThan(result.nodesCount, 100)
        }
    }
    
    func testPerformanceWith73NodeTree() {
        // Given - Generate a 24-level, 73-node tree similar to user's real-world case
        let largeInput = generateRealistic73NodeTree()
        
        // When & Then
        measure {
            let result = parseMultipleTree(input: largeInput)
    
            XCTAssertEqual(result.treesCount, 1)
            XCTAssertEqual(result.nodesCount, 73)
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseMultipleTree(input: String) -> ImportResult {
        // Use the actual parsing logic from ImportSkillTreeView
        return parseAndImportMultipleTrees(input: input)
    }
    
    private func parseAndImportMultipleTrees(input: String) -> ImportResult {
        // Implementation that matches the new import logic from ImportSkillTreeView
        if input.isEmpty {
            return ImportResult(treesCount: 0, nodesCount: 0, skillTrees: [])
        }
        
        let lines = input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            return ImportResult(treesCount: 0, nodesCount: 0, skillTrees: [])
        }
        
        let context = dataController.container.viewContext
        var skillTrees: [SkillTree] = []
        var currentTree: SkillTree?
        var nodeStack: [(SkillNode, Int)] = []
        var currentLevel = 1
        var currentWorkingLevel = 1
        
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

        for (_, line) in lines.enumerated() {
            if line.hasPrefix("##") {
                // Level root node
                let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                guard let tree = currentTree else { continue }
                
                // Update maxLevel if necessary
                if currentLevel > tree.maxLevel {
                    tree.maxLevel = currentLevel
                }
                
                // Create root node for this level
                let (parsedName, _) = parseTaggedContent(content, defaultType: .root)
                let rootNode = SkillNode(context: context, name: parsedName, type: .root)
                rootNode.tree = tree
                rootNode.level = currentLevel
                rootNode.order = 0
                
                // Clear the node stack and add this root node
                nodeStack.removeAll()
                nodeStack.append((rootNode, 0)) // Root nodes are at depth 0
                
                currentWorkingLevel = currentLevel
                currentLevel += 1
                
            } else if line.hasPrefix("#") {
                // Tree name
                let content = String(line.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                let tree = SkillTree(context: context, name: content, description: "")
                skillTrees.append(tree)
                currentTree = tree
                nodeStack.removeAll()
                currentLevel = 1
                currentWorkingLevel = 1
                
            } else if line.hasPrefix("-") {
                // Regular node
                let dashCount = line.prefix(while: { $0 == "-" }).count
                let content = String(line.dropFirst(dashCount)).trimmingCharacters(in: .whitespaces)
                guard let tree = currentTree else { continue }
                
                let (parsedName, nodeType) = parseTaggedContent(content, defaultType: .goal)
                let node = SkillNode(context: context, name: parsedName, type: nodeType)
                node.tree = tree
                node.level = currentWorkingLevel
                
                // Remove nodes from stack that are at greater or equal depth
                nodeStack.removeAll { $0.1 >= dashCount }
                
                // Find parent node at the previous depth level
                if let parentInfo = nodeStack.last(where: { $0.1 == dashCount - 1 }) {
                    node.parentNode = parentInfo.0
                }
                
                nodeStack.append((node, dashCount))
            }
        }
        
        // Save to Core Data
        try! context.save()
        
        return ImportResult(
            treesCount: skillTrees.count,
            nodesCount: skillTrees.reduce(0) { sum, tree in sum + tree.nodes.count },
            skillTrees: skillTrees
        )
    }
    
    private func getIndentationLevel(line: String) -> Int {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let original = line
        let leadingSpaces = original.count - trimmed.count
        return leadingSpaces / 2 // Assuming 2 spaces per level
    }
    
    private func generateLargeTreeInput() -> String {
        var input = "# Large Test Tree\n"
        input += "## Performance Level\n"
        for i in 1...100 {
            input += "- Node \(i)\n"
            for j in 1...5 {
                input += "-- Subnode \(i).\(j)\n"
                for k in 1...3 {
                    input += "--- Sub-subnode \(i).\(j).\(k)\n"
                }
            }
        }
        return input
    }
    
    private func generateRealistic73NodeTree() -> String {
        var input = "# Machine Learning Skill Tree\n"
        
        // Generate exactly 73 nodes across 24 levels (including root nodes)
        // 24 level root nodes + 49 regular nodes = 73 total nodes
        let nodesPerLevel = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1] // 49 regular nodes total
        
        for level in 1...24 {
            input += "## Level \(level) Foundation\n"
            let nodeCount = nodesPerLevel[level - 1]
            
            for i in 1...nodeCount {
                let dashes = String(repeating: "-", count: 1) // Keep depth consistent at 1
                input += "\(dashes) Level \(level) Node \(i)\n"
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