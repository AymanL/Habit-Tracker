import SwiftUI
import CoreData

struct EditCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var selectedColor: HabitColor
    
    private let category: Category?
    
    init(category: Category? = nil) {
        self.category = category
        _name = State(initialValue: category?.name_ ?? "")
        _selectedColor = State(initialValue: HabitColor(rawValue: category?.color_ ?? "blue") ?? .blue)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Category Name", text: $name)
                
                ColorsPickerView(selectedColor: $selectedColor)
            }
        }
        .navigationTitle(category == nil ? "New Category" : "Edit Category")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    private func save() {
        if let category = category {
            // Update existing category
            category.name_ = name
            category.color_ = selectedColor.rawValue
        } else {
            // Create new category
            let newCategory = Category(context: viewContext)
            newCategory.id_ = UUID()
            newCategory.name_ = name
            newCategory.color_ = selectedColor.rawValue
            newCategory.creationDate_ = Date()
            
            // Set initial order to be the last in the list
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.order_, ascending: false)]
            request.fetchLimit = 1
            
            if let lastCategory = try? viewContext.fetch(request).first {
                newCategory.order_ = Int64(lastCategory.order_) + 1
            } else {
                newCategory.order_ = 0
            }
        }
        
        try? viewContext.save()
    }
}

struct EditCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditCategoryView()
                .environmentObject(DataController.preview)
        }
    }
} 