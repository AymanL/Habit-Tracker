import Foundation
import CoreData

// MARK: - Node Type Enum

enum SkillNodeType: String, CaseIterable {
    case standalone = "standalone"
    case oneShot = "oneShot"
    case habitLinked = "habitLinked"
    
    var displayName: String {
        switch self {
        case .standalone:
            return "Standalone"
        case .oneShot:
            return "One Shot"
        case .habitLinked:
            return "Habit Linked"
        }
    }
    
    var description: String {
        switch self {
        case .standalone:
            return "A simple task that can be completed once"
        case .oneShot:
            return "A one-time event that can only be completed once"
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
        get { SkillNodeType(rawValue: nodeType_ ?? "standalone") ?? .standalone }
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
        case .standalone, .oneShot:
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
        return SkillNode(context: context, name: "Example Node", type: .standalone, description: "A sample node for testing")
    }
} 