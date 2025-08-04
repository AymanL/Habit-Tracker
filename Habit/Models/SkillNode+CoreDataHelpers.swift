import Foundation
import CoreData
import SwiftUI

// MARK: - Daily Completion Status

enum DailyCompletionStatus {
    case completed
    case completedViaHabit
    case notCompleted
    
    var displayName: String {
        switch self {
        case .completed:
            return "Completed"
        case .completedViaHabit:
            return "Completed via Habit"
        case .notCompleted:
            return "Not Completed"
        }
    }
    
    var color: Color {
        switch self {
        case .completed, .completedViaHabit:
            return .green
        case .notCompleted:
            return .secondary
        }
    }
    
    var icon: String {
        switch self {
        case .completed:
            return "checkmark.circle.fill"
        case .completedViaHabit:
            return "checkmark.circle.fill"
        case .notCompleted:
            return "circle"
        }
    }
}

// MARK: - Node Type Enum

enum SkillNodeType: String, CaseIterable {
    case goal = "goal"
    case activity = "activity"
    case habitLinked = "habitLinked"
    
    var displayName: String {
        switch self {
        case .goal:
            return "Goal"
        case .activity:
            return "Activity"
        case .habitLinked:
            return "Habit Linked"
        }
    }
    
    var description: String {
        switch self {
        case .goal:
            return "A goal that can be achieved once"
        case .activity:
            return "An activity that can be completed multiple times"
        case .habitLinked:
            return "Linked to an existing habit for daily tracking"
        }
    }
}

extension SkillNode {
    // MARK: - Convenience Properties
    
    public var id: UUID {
        get { id_ ?? UUID() }
        set { id_ = newValue }
    }
    
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }
    
    var nodeDescription: String {
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
    
    var completionDate: Date? {
        get { completionDate_ }
        set { completionDate_ = newValue }
    }
    
    var isCompleted: Bool {
        get { isCompleted_ }
        set { 
            isCompleted_ = newValue
            if newValue && completionDate == nil {
                completionDate = Date()
            } else if !newValue {
                completionDate = nil
            }
        }
    }
    
    var nodeType: SkillNodeType {
        get { SkillNodeType(rawValue: nodeType_ ?? "goal") ?? .goal }
        set { nodeType_ = newValue.rawValue }
    }
    
    var positionX: Double {
        get { positionX_ }
        set { positionX_ = newValue }
    }
    
    var positionY: Double {
        get { positionY_ }
        set { positionY_ = newValue }
    }
    
    var tree: SkillTree? {
        get { tree_ }
        set { tree_ = newValue }
    }
    
    var habit: Habit? {
        get { habit_ }
        set { habit_ = newValue }
    }
    
    // MARK: - Computed Properties
    
    var position: CGPoint {
        get { CGPoint(x: positionX, y: positionY) }
        set { 
            positionX = newValue.x
            positionY = newValue.y
        }
    }
    
    var canBeCompleted: Bool {
        switch nodeType {
        case .goal, .activity:
            return !isCompleted
        case .habitLinked:
            return habit != nil && !isCompleted
        }
    }
    
    var isHabitLinked: Bool {
        nodeType == .habitLinked && habit != nil
    }
    
    // MARK: - Initialization
    
    convenience init(context: NSManagedObjectContext, name: String, type: SkillNodeType, description: String = "") {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.nodeDescription = description
        self.nodeType = type
        self.creationDate = Date()
        self.isCompleted = false
        
        // Set initial order to be the last in the list
        let request: NSFetchRequest<SkillNode> = SkillNode.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SkillNode.order_, ascending: false)]
        request.fetchLimit = 1
        
        if let lastNode = try? context.fetch(request).first {
            self.order_ = Int64(lastNode.order_) + 1
        } else {
            self.order_ = 0
        }
        
        print("📋 Created SkillNode: \(name) (\(type.displayName))")
    }
    
    // MARK: - Methods
    
    func complete() {
        guard canBeCompleted else {
            print("⚠️ Cannot complete node: \(name)")
            return
        }
        
        isCompleted = true
        print("✅ Completed SkillNode: \(name)")
    }
    
    /// Check if the node is completed for today
    func isCompletedForToday() -> Bool {
        if isCompleted {
            return true
        }
        
        // For habit-linked nodes, check if the linked habit is completed for today
        if nodeType == .habitLinked, let linkedHabit = habit {
            return linkedHabit.isCompleted(for: Date())
        }
        
        return false
    }
    
    /// Get the daily completion status for habit-linked nodes
    func getDailyCompletionStatus() -> DailyCompletionStatus {
        switch nodeType {
        case .goal, .activity:
            return isCompleted ? .completed : .notCompleted
        case .habitLinked:
            if let linkedHabit = habit {
                if linkedHabit.isCompleted(for: Date()) {
                    return .completedViaHabit
                } else {
                    return .notCompleted
                }
            } else {
                return .notCompleted
            }
        }
    }
    
    /// Mark the node as completed for today (for habit-linked nodes, this syncs with the habit)
    func completeForToday() {
        switch nodeType {
        case .goal, .activity:
            if !isCompleted {
                complete()
            }
        case .habitLinked:
            if let linkedHabit = habit {
                // Complete the linked habit for today
                linkedHabit.addCompletedDate(Date())
                print("✅ Completed habit-linked node '\(name)' via habit '\(linkedHabit.title)'")
            }
        }
    }
    
    /// Uncomplete the node for today (for habit-linked nodes, this syncs with the habit)
    func uncompleteForToday() {
        switch nodeType {
        case .goal, .activity:
            if isCompleted {
                isCompleted = false
            }
        case .habitLinked:
            if let linkedHabit = habit {
                // Uncomplete the linked habit for today
                linkedHabit.removeCompletedDate(Date())
                print("❌ Uncompleted habit-linked node '\(name)' via habit '\(linkedHabit.title)'")
            }
        }
    }
    
    func linkToHabit(_ habit: Habit) {
        guard nodeType == .habitLinked else {
            print("⚠️ Cannot link habit to non-habit-linked node: \(name)")
            return
        }
        
        self.habit = habit
        print("🔗 Linked SkillNode '\(name)' to Habit '\(habit.title)'")
    }
    
    func unlinkHabit() {
        guard nodeType == .habitLinked else {
            print("⚠️ Cannot unlink habit from non-habit-linked node: \(name)")
            return
        }
        
        self.habit = nil
        print("🔗 Unlinked SkillNode '\(name)' from habit")
    }
    
    // MARK: - Example Data
    
    static var example: SkillNode {
        let context = DataController.preview.container.viewContext
        return SkillNode(context: context, name: "Example Node", type: .goal, description: "A sample node for testing")
    }
} 