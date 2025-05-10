import Foundation
import CoreData

extension Category {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }
    
    // MARK: - Convenience Properties
    
    var id: UUID {
        get { id_ ?? UUID() }
        set { id_ = newValue }
    }
    
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }
    
    var color: HabitColor {
        get { .init(rawValue: color_ ?? "blue") ?? .blue }
        set { color_ = newValue.rawValue }
    }
    
    var order: Int {
        get { Int(order_) }
        set { order_ = Int64(newValue) }
    }
    
    var creationDate: Date {
        get { creationDate_ ?? Date() }
        set { creationDate_ = newValue }
    }
    
    var habits: [Habit] {
        get { habits_?.allObjects as? [Habit] ?? [] }
        set { habits_ = NSSet(array: newValue) }
    }
    
    // MARK: - Initialization
    
    convenience init(context: NSManagedObjectContext, name: String, color: HabitColor) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.color = color
        self.creationDate = Date()
        
        // Set initial order to be the last in the list
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.order_, ascending: false)]
        request.fetchLimit = 1
        
        if let lastCategory = try? context.fetch(request).first {
            self.order_ = Int64(lastCategory.order_) + 1
        } else {
            self.order_ = 0
        }
    }
    
    // MARK: - Example Data
    
    static var example: Category {
        let dataController = DataController.preview
        let viewContext = dataController.container.viewContext
        
        let category = Category(context: viewContext, name: "Example Category", color: .blue)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return category
    }
} 