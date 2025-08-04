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
        
        XCTAssertEqual(standaloneNode.nodeType.displayName, "Standalone")
        XCTAssertEqual(oneShotNode.nodeType.displayName, "One Shot")
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
        dataController.createSkillNode(name: "Debug Node", type: .goal, in: tree)
        
        // These should not crash and should print debug info
        dataController.debugAllEntities()
        dataController.debugSkillTrees()
        dataController.debugSkillNodes()
        dataController.createTestSkillTree()
    }
} 