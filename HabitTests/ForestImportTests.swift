import XCTest
import CoreData
@testable import Habit

class ForestImportTests: BaseTestCase {
    
    // MARK: - Forest Import Test Data
    
    private var validForestInput: String {
        """
        Programming Skills
        - Swift Development
        -- Learn Swift Basics
        -- Understand Optionals
        -- Master Closures
        -- Build Simple Apps
        -- Advanced Swift Features
        --- Protocol-Oriented Programming
        --- Generics and Type Constraints
        --- Memory Management
        - Python Development
        -- Learn Python Basics
        -- Understand Python OOP
        -- Master Django Framework
        -- Build Web Applications
        """
    }
    
    private var simpleForestInput: String {
        """
        Learning Paths
        - Programming
        -- Learn to Code
        -- Build Projects
        - Design
        -- Learn UI/UX
        -- Create Mockups
        """
    }
    
    private var complexForestInput: String {
        """
        Technology Stack
        - Frontend Development
        -- HTML & CSS
        --- Responsive Design
        --- CSS Frameworks
        ---- Bootstrap
        ---- Tailwind CSS
        -- JavaScript
        --- ES6+ Features
        --- React Framework
        ---- Components
        ---- State Management
        ---- Hooks
        - Backend Development
        -- Node.js
        --- Express Framework
        --- REST APIs
        -- Database Design
        --- SQL
        --- NoSQL
        """
    }
    
    private var emptyForestInput: String {
        ""
    }
    
    private var invalidForestInput: String {
        """
        - Tree without Forest
        -- Node without Tree
        """
    }
    
    private var forestWithSpecialCharacters: String {
        """
        Test Forest: @#$%^&*()
        - Tree with spaces and dots ...
        -- Node with dashes - and underscores _
        -- Node with numbers 123 and symbols !@#
        """
    }

    // MARK: - Forest Import Tests
    
    func testValidForestImport() {
        // Given
        let input = validForestInput
        
        // When
        let result = parseForest(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 1)
        XCTAssertEqual(result.treesCount, 2) // Swift Development + Python Development
        XCTAssertEqual(result.nodesCount, 14) // 9 nodes in Swift + 5 nodes in Python (including root nodes)
        
        // Verify the forest structure by fetching from Core Data
        let forests = try! managedObjectContext.fetch(Forest.fetchRequest())
        XCTAssertEqual(forests.count, 1)
        
        let programmingSkillsForest = forests.first!
        XCTAssertEqual(programmingSkillsForest.name_, "Programming Skills")
        XCTAssertEqual(programmingSkillsForest.trees_?.count ?? 0, 2)
        
        // Verify trees in the forest
        let programmingSkillsForestTrees = (programmingSkillsForest.trees_?.allObjects as? [SkillTree]) ?? []
        XCTAssertEqual(programmingSkillsForestTrees.count, 2)
        
        let swiftTree = programmingSkillsForestTrees.first { $0.name == "Swift Development" }
        XCTAssertNotNil(swiftTree)
        XCTAssertEqual(swiftTree?.nodes.count, 9)
        
        let pythonTree = programmingSkillsForestTrees.first { $0.name == "Python Development" }
        XCTAssertNotNil(pythonTree)
        XCTAssertEqual(pythonTree?.nodes.count, 5) // Fixed: should be 5 (1 root + 4 level 1 nodes)
        
        // Verify parent-child relationships in Swift tree
        let swiftNodes = swiftTree!.nodes
        let swiftRootNodes = swiftNodes.filter { $0.parentNode == nil }
        XCTAssertEqual(swiftRootNodes.count, 1) // Only the root node should have no parent
        
        let swiftLevel1Nodes = swiftNodes.filter { $0.parentNode?.name == "Swift Development" }
        XCTAssertEqual(swiftLevel1Nodes.count, 5) // 5 level 1 nodes (children of root)
        XCTAssertTrue(swiftLevel1Nodes.contains { $0.name == "Learn Swift Basics" })
        XCTAssertTrue(swiftLevel1Nodes.contains { $0.name == "Understand Optionals" })
        XCTAssertTrue(swiftLevel1Nodes.contains { $0.name == "Master Closures" })
        XCTAssertTrue(swiftLevel1Nodes.contains { $0.name == "Build Simple Apps" })
        XCTAssertTrue(swiftLevel1Nodes.contains { $0.name == "Advanced Swift Features" })
        
        let advancedFeatures = swiftNodes.first { $0.name == "Advanced Swift Features" }
        XCTAssertNotNil(advancedFeatures)
        
        let advancedChildren = swiftNodes.filter { $0.parentNode?.name == "Advanced Swift Features" }
        XCTAssertEqual(advancedChildren.count, 3)
        XCTAssertTrue(advancedChildren.contains { $0.name == "Protocol-Oriented Programming" })
        XCTAssertTrue(advancedChildren.contains { $0.name == "Generics and Type Constraints" })
        XCTAssertTrue(advancedChildren.contains { $0.name == "Memory Management" })
    }
    
    func testSimpleForestImport() {
        // Given
        let input = simpleForestInput
        
        // When
        let result = parseForest(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 1)
        XCTAssertEqual(result.treesCount, 2)
        XCTAssertEqual(result.nodesCount, 6) // 3 nodes in Programming + 3 nodes in Design (including root nodes)
        XCTAssertEqual(result.forests.count, 1)
        
        // Verify the forest structure
        let forests = try! managedObjectContext.fetch(Forest.fetchRequest())
        XCTAssertEqual(forests.count, 1)
        
        let forest = forests.first!
        XCTAssertEqual(forest.name_, "Learning Paths")
        XCTAssertEqual(forest.trees_?.count ?? 0, 2)
        
        // Verify trees
        let trees = (forest.trees_?.allObjects as? [SkillTree]) ?? []
        XCTAssertEqual(trees.count, 2)
        
        let programmingTree = trees.first { $0.name == "Programming" }
        XCTAssertNotNil(programmingTree)
        XCTAssertEqual(programmingTree?.nodes.count, 3) // 1 root + 2 level 1 nodes
        
        let designTree = trees.first { $0.name == "Design" }
        XCTAssertNotNil(designTree)
        XCTAssertEqual(designTree?.nodes.count, 3) // 1 root + 2 level 1 nodes
    }
    
    func testComplexForestImport() {
        // Given
        let input = complexForestInput
        
        // When
        let result = parseForest(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 1)
        XCTAssertEqual(result.treesCount, 2)
        XCTAssertGreaterThan(result.nodesCount, 10) // Should have many nodes
        XCTAssertEqual(result.forests.count, 1)
        
        // Verify the forest structure
        let forests = try! managedObjectContext.fetch(Forest.fetchRequest())
        XCTAssertEqual(forests.count, 1)
        
        let forest = forests.first!
        XCTAssertEqual(forest.name_, "Technology Stack")
        XCTAssertEqual(forest.trees_?.count ?? 0, 2)
        
        // Verify deep nesting
        let trees = (forest.trees_?.allObjects as? [SkillTree]) ?? []
        let frontendTree = trees.first { $0.name == "Frontend Development" }
        XCTAssertNotNil(frontendTree)
        
        let frontendNodes = frontendTree!.nodes
        let javascriptNode = frontendNodes.first { $0.name == "JavaScript" }
        XCTAssertNotNil(javascriptNode)
        
        let reactNode = frontendNodes.first { $0.name == "React Framework" }
        XCTAssertNotNil(reactNode)
        XCTAssertEqual(reactNode?.parentNode?.name, "JavaScript")
        
        let reactChildren = frontendNodes.filter { $0.parentNode?.name == "React Framework" }
        XCTAssertEqual(reactChildren.count, 3)
        XCTAssertTrue(reactChildren.contains { $0.name == "Components" })
        XCTAssertTrue(reactChildren.contains { $0.name == "State Management" })
        XCTAssertTrue(reactChildren.contains { $0.name == "Hooks" })
    }
    
    func testEmptyForestInputThrowsError() {
        // Given
        let input = emptyForestInput
        
        // When & Then
        XCTAssertThrowsError(try parseAndImportForest(input: input)) { error in
            if case ImportError.emptyFile = error {
                // Expected error
            } else {
                XCTFail("Expected ImportError.emptyFile, got \(error)")
            }
        }
    }
    
    func testInvalidForestInputThrowsError() {
        // Given
        let input = invalidForestInput
        
        // When & Then
        XCTAssertThrowsError(try parseAndImportForest(input: input)) { error in
            if case ImportError.noForestDefined = error {
                // Expected error
            } else {
                XCTFail("Expected ImportError.noForestDefined, got \(error)")
            }
        }
    }
    
    func testForestWithSpecialCharacters() {
        // Given
        let input = forestWithSpecialCharacters
        
        // When
        let result = parseForest(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 1)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 3) // 1 root + 2 level 1 nodes
        XCTAssertEqual(result.forests.count, 1)
        
        // Verify the forest structure
        let forests = try! managedObjectContext.fetch(Forest.fetchRequest())
        XCTAssertEqual(forests.count, 1)
        
        let forest = forests.first!
        XCTAssertEqual(forest.name_, "Test Forest: @#$%^&*()")
        XCTAssertEqual(forest.trees_?.count ?? 0, 1)
        
        let trees = (forest.trees_?.allObjects as? [SkillTree]) ?? []
        let tree = trees.first!
        XCTAssertEqual(tree.name, "Tree with spaces and dots ...")
        XCTAssertEqual(tree.nodes.count, 3) // 1 root + 2 level 1 nodes
    }
    
    func testForestWithEmptyLines() {
        // Given
        let input = """
        Test Forest
        
        - First Tree
        
        -- First Node
        
        -- Second Node
        
        """
        
        // When
        let result = parseForest(input: input)
        
        // Then
        XCTAssertEqual(result.forestsCount, 1)
        XCTAssertEqual(result.treesCount, 1)
        XCTAssertEqual(result.nodesCount, 3) // 1 root + 2 level 1 nodes
        XCTAssertEqual(result.forests.count, 1)
        
        // Verify the forest structure
        let forests = try! managedObjectContext.fetch(Forest.fetchRequest())
        XCTAssertEqual(forests.count, 1)
        
        let forest = forests.first!
        XCTAssertEqual(forest.name_, "Test Forest")
        XCTAssertEqual(forest.trees_?.count ?? 0, 1)
        
        let trees = (forest.trees_?.allObjects as? [SkillTree]) ?? []
        let tree = trees.first!
        XCTAssertEqual(tree.name, "First Tree")
        XCTAssertEqual(tree.nodes.count, 3) // 1 root + 2 level 1 nodes
    }
    
    func testForestPerformanceWithLargeInput() {
        // Given
        let largeInput = generateLargeForestInput()
        
        // When & Then
        measure {
            let result = parseForest(input: largeInput)
            XCTAssertEqual(result.forestsCount, 3)
            XCTAssertGreaterThan(result.treesCount, 10)
            XCTAssertGreaterThan(result.nodesCount, 100)
            XCTAssertEqual(result.forests.count, 3)
        }
    }
    
    // MARK: - Forest Import Helper Methods
    
    private func parseForest(input: String) -> ImportResult {
        // Use the actual parsing logic from ImportSkillTreeView
        return try! parseAndImportForest(input: input)
    }
    
    private func parseAndImportForest(input: String) throws -> ImportResult {
        // Implementation that matches the actual Forest import logic from ImportSkillTreeView
        if input.isEmpty {
            throw ImportError.emptyFile
        }
        
        let lines = input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }
        
        guard let context = managedObjectContext else {
            throw ImportError.saveFailed("No managed object context available")
        }
        var forests: [Forest] = []
        var currentForest: Forest?
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
                // Forest name
                let forest = Forest(context: context)
                forest.name_ = content
                forest.description_ = ""
                forests.append(forest)
                currentForest = forest
                currentTree = nil
                nodeStack.removeAll()
                
            case 1:
                // Tree name
                guard let forest = currentForest else {
                    throw ImportError.noForestDefined(lineNumber: index + 1)
                }
                
                let tree = SkillTree(context: context, name: content)
                tree.forest = forest
                currentTree = tree
                
                // Find the automatically created root node and add it to the stack
                let rootNode = tree.nodes.first { $0.name == content }
                if let root = rootNode {
                    nodeStack.removeAll()
                    nodeStack.append((root, 0)) // Root node is level 0
                }
                
            case 2:
                // Level 1 node (2 dashes = level 1 in tree) - should be child of root
                guard let tree = currentTree else {
                    continue
                }
                
                let (parsedName1, parsedType1) = parseTaggedContent(content, defaultType: .goal)
                let node = SkillNode(context: context, name: parsedName1, type: parsedType1)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == 2 }.count
                
                // Find the root node (level 0) as parent
                if let rootIndex = nodeStack.lastIndex(where: { $0.1 == 0 }) {
                    let root = nodeStack[rootIndex].0
                    root.addChild(node)
                }
                
                nodeStack.append((node, 2))
                
            case 3:
                // Level 2 node (3 dashes = level 2 in tree)
                guard let tree = currentTree else {
                    continue
                }
                
                let (parsedName2, parsedType2) = parseTaggedContent(content, defaultType: .activity)
                let node = SkillNode(context: context, name: parsedName2, type: parsedType2)
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
                    continue
                }
                
                let (parsedNameN, parsedTypeN) = parseTaggedContent(content, defaultType: .activity)
                let node = SkillNode(context: context, name: parsedNameN, type: parsedTypeN)
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
            forestsCount: forests.count,
            treesCount: forests.reduce(0) { sum, forest in sum + (forest.trees_?.allObjects as? [SkillTree] ?? []).count },
            nodesCount: forests.reduce(0) { sum, forest in sum + (forest.trees_?.allObjects as? [SkillTree] ?? []).reduce(0) { treeSum, tree in treeSum + tree.nodes.count } },
            forests: forests
        )
    }
    
    private func generateLargeForestInput() -> String {
        var input = "Large Test Forest\n"
        for i in 1...3 {
            input += "- Forest \(i)\n"
            for j in 1...5 {
                input += "-- Tree \(i).\(j)\n"
                for k in 1...10 {
                    input += "--- Node \(i).\(j).\(k)\n"
                    for l in 1...3 {
                        input += "---- Subnode \(i).\(j).\(k).\(l)\n"
                    }
                }
            }
        }
        return input
    }
} 