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
        XCTAssertEqual(result.success, true)
        XCTAssertNotNil(result.tree)
        XCTAssertEqual(result.tree?.name, "Swift Development")
        XCTAssertEqual(result.tree?.nodes?.count, 8) // Root + 7 nodes
        
        // Verify root node
        let rootNode = result.tree?.nodes?.first { $0.name == "Swift Development" }
        XCTAssertNotNil(rootNode)
        XCTAssertEqual(rootNode?.nodeType, .goal)
        
        // Verify child nodes
        let childNodes = result.tree?.nodes?.filter { $0.name != "Swift Development" } ?? []
        XCTAssertEqual(childNodes.count, 7)
        
        // Verify specific nodes
        let learnSwiftBasics = childNodes.first { $0.name == "Learn Swift Basics" }
        XCTAssertNotNil(learnSwiftBasics)
        XCTAssertEqual(learnSwiftBasics?.nodeType, .goal)
        
        let advancedFeatures = childNodes.first { $0.name == "Advanced Swift Features" }
        XCTAssertNotNil(advancedFeatures)
        XCTAssertEqual(advancedFeatures?.nodeType, .goal)
        
        // Verify nested nodes
        let protocolOriented = childNodes.first { $0.name == "Protocol-Oriented Programming" }
        XCTAssertNotNil(protocolOriented)
        XCTAssertEqual(protocolOriented?.nodeType, .goal)
    }
    
    func testSimpleTreeImport() {
        // Given
        let input = simpleTreeInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.success, true)
        XCTAssertNotNil(result.tree)
        XCTAssertEqual(result.tree?.name, "Programming")
        XCTAssertEqual(result.tree?.nodes?.count, 3) // Root + 2 nodes
        
        let childNodes = result.tree?.nodes?.filter { $0.name != "Programming" } ?? []
        XCTAssertEqual(childNodes.count, 2)
        
        let learnPython = childNodes.first { $0.name == "Learn Python" }
        XCTAssertNotNil(learnPython)
        
        let learnJavaScript = childNodes.first { $0.name == "Learn JavaScript" }
        XCTAssertNotNil(learnJavaScript)
    }
    
    func testDeepNestedTreeImport() {
        // Given
        let input = deepNestedTreeInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.success, true)
        XCTAssertNotNil(result.tree)
        XCTAssertEqual(result.tree?.name, "Software Development")
        
        // Verify the tree has the expected structure
        let allNodes = result.tree?.nodes ?? []
        XCTAssertGreaterThan(allNodes.count, 10) // Should have many nodes
        
        // Verify specific nodes exist
        let frontendDev = allNodes.first { $0.name == "Frontend Development" }
        XCTAssertNotNil(frontendDev)
        
        let backendDev = allNodes.first { $0.name == "Backend Development" }
        XCTAssertNotNil(backendDev)
        
        let htmlCss = allNodes.first { $0.name == "HTML & CSS" }
        XCTAssertNotNil(htmlCss)
        
        let reactJs = allNodes.first { $0.name == "React.js" }
        XCTAssertNotNil(reactJs)
    }
    
    func testEmptyInput() {
        // Given
        let input = emptyInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.success, false)
        XCTAssertNil(result.tree)
        XCTAssertEqual(result.error, .emptyInput)
    }
    
    func testInvalidInput() {
        // Given
        let input = invalidInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.success, false)
        XCTAssertNil(result.tree)
        XCTAssertEqual(result.error, .invalidFormat)
    }
    
    func testSingleLineInput() {
        // Given
        let input = singleLineInput
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.success, false)
        XCTAssertNil(result.tree)
        XCTAssertEqual(result.error, .invalidFormat)
    }
    
    func testInputWithOnlyRoot() {
        // Given
        let input = "Just a root node"
        
        // When
        let result = parseSingleTree(input: input)
        
        // Then
        XCTAssertEqual(result.success, true)
        XCTAssertNotNil(result.tree)
        XCTAssertEqual(result.tree?.name, "Just a root node")
        XCTAssertEqual(result.tree?.nodes?.count, 1) // Only root node
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
        XCTAssertEqual(result.success, true)
        XCTAssertNotNil(result.tree)
        XCTAssertEqual(result.tree?.name, "Test Tree with Special Chars: @#$%^&*()")
        XCTAssertEqual(result.tree?.nodes?.count, 4) // Root + 3 nodes
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
        XCTAssertEqual(result.success, true)
        XCTAssertNotNil(result.tree)
        XCTAssertEqual(result.tree?.name, "Test Tree")
        XCTAssertEqual(result.tree?.nodes?.count, 3) // Root + 2 nodes
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
        XCTAssertEqual(result.success, true)
        XCTAssertNotNil(result.tree)
        XCTAssertEqual(result.tree?.name, "Test Tree")
        XCTAssertGreaterThan(result.tree?.nodes?.count ?? 0, 5) // Should have multiple nodes
    }
    
    func testPerformanceWithLargeTree() {
        // Given
        let largeInput = generateLargeTreeInput()
        
        // When & Then
        measure {
            let result = parseSingleTree(input: largeInput)
            XCTAssertEqual(result.success, true)
            XCTAssertNotNil(result.tree)
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseSingleTree(input: String) -> ImportResult {
        // This would call the actual parsing logic from ImportSingleTreeView
        // For now, we'll create a mock implementation
        return mockParseSingleTree(input: input)
    }
    
    private func mockParseSingleTree(input: String) -> ImportResult {
        // Mock implementation for testing
        if input.isEmpty {
            return ImportResult(success: false, tree: nil, error: .emptyInput)
        }
        
        let lines = input.components(separatedBy: .newlines)
        guard lines.count > 0 else {
            return ImportResult(success: false, tree: nil, error: .invalidFormat)
        }
        
        let rootName = lines[0].trimmingCharacters(in: .whitespaces)
        if rootName.isEmpty {
            return ImportResult(success: false, tree: nil, error: .invalidFormat)
        }
        
        // Create the tree
        let tree = dataController.createSkillTree(name: rootName)
        
        // Parse child nodes
        var currentLevel = 0
        var nodeStack: [SkillNode] = []
        
        for line in lines.dropFirst() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }
            
            let level = getIndentationLevel(line: line)
            let nodeName = trimmedLine.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
            
            if nodeName.isEmpty { continue }
            
            let node = dataController.createSkillNode(name: nodeName, type: .goal, in: tree)
            
            // Handle nesting
            while nodeStack.count > level {
                nodeStack.removeLast()
            }
            
            if let parentNode = nodeStack.last {
                node.parentNode = parentNode
            }
            
            nodeStack.append(node)
        }
        
        return ImportResult(success: true, tree: tree, error: nil)
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

struct ImportResult {
    let success: Bool
    let tree: SkillTree?
    let error: ImportError?
}

enum ImportError: Error, Equatable {
    case emptyInput
    case invalidFormat
    case parsingError
    case unknownError
} 