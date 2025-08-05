import SwiftUI

struct EditSkillTreeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    let forest: Forest?
    
    @State private var name = ""
    @State private var description = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tree Information")) {
                    TextField("Tree Name", text: $name)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Forest")) {
                    if let forest = forest {
                        HStack {
                            Text("Forest")
                            Spacer()
                            Text(forest.name_ ?? "Unnamed Forest")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No forest selected")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("New Skill Tree")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTree()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveTree() {
        guard !name.isEmpty else {
            alertMessage = "Please enter a tree name"
            showingAlert = true
            return
        }
        
        let context = dataController.container.viewContext
        
        do {
            let tree = SkillTree(context: context, name: name, description: description)
            
            // Associate with forest if provided
            if let forest = forest {
                tree.forest = forest
            }
            
            try context.save()
            
            print("✅ Created SkillTree: \(name)")
            dismiss()
            
        } catch {
            alertMessage = "Failed to create tree: \(error.localizedDescription)"
            showingAlert = true
            print("❌ Error creating SkillTree: \(error)")
        }
    }
}

#Preview {
    EditSkillTreeView(forest: nil)
        .environmentObject(DataController.preview)
} 