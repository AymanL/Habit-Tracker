import SwiftUI
import CoreData

struct CategoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var dataController: DataController
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order_, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    
    var body: some View {
        List {
            ForEach(categories) { category in
                CategoryRowView(category: category, editingCategory: $editingCategory)
                    .id(category.id)
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
            .listRowSeparator(.hidden)
            .buttonStyle(.plain)
            .listRowInsets(.init(top: 8, leading: 16, bottom: 6, trailing: 16))
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCategory = true }) {
                    Label("Add Category", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            NavigationView {
                EditCategoryView()
            }
        }
        .sheet(item: $editingCategory) { category in
            NavigationView {
                EditCategoryView(category: category)
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        offsets.map { categories[$0] }.forEach(dataController.delete(_:))
        dataController.save()
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        var revisedItems: [Category] = categories.map { $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        // Update the order for each category
        for (index, category) in revisedItems.enumerated() {
            category.order_ = Int64(index)
        }
        
        dataController.save()
    }
}

struct CategoryRowView: View {
    let category: Category
    @Binding var editingCategory: Category?
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(HabitColor(rawValue: category.color_ ?? "blue") ?? .blue))
                .frame(width: 12, height: 12)
            
            Text(category.name_ ?? "")
                .font(.headline)
            
            Spacer()
            
            Text("\(category.habits_?.count ?? 0) habits")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            editingCategory = category
        }
    }
}

struct CategoryListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CategoryListView()
                .environmentObject(DataController.preview)
        }
    }
} 