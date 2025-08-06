import SwiftUI

struct EditForestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State private var forestName = ""
    @State private var forestDescription = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let forest: Forest?
    
    init(forest: Forest? = nil) {
        self.forest = forest
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Forest Details") {
                    TextField("Forest Name", text: $forestName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (Optional)", text: $forestDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                if let forest = forest {
                    Section("Forest Information") {
                        HStack {
                            Text("Created")
                            Spacer()
                            Text((forest.creationDate_ ?? Date()).formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Trees")
                            Spacer()
                            Text("\(calculateTotalTreesCount(for: forest))")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Total Nodes")
                            Spacer()
                            Text("\(calculateTotalNodesCount(for: forest))")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Completion")
                            Spacer()
                            Text("\(Int(calculateForestCompletion(for: forest) * 100))%")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(forest == nil ? "New Forest" : "Edit Forest")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveForest()
                }
                .disabled(forestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .onAppear {
                if let forest = forest {
                    forestName = forest.name_ ?? ""
                    forestDescription = forest.description_ ?? ""
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveForest() {
        let trimmedName = forestName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = forestDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Forest name cannot be empty"
            showingAlert = true
            return
        }
        
        do {
            if let existingForest = forest {
                // Update existing forest
                existingForest.name_ = trimmedName
                existingForest.description_ = trimmedDescription
                dataController.save()
                print("✅ Updated forest: \(trimmedName)")
            } else {
                // Create new forest
                let newForest = Forest(context: dataController.container.viewContext)
                newForest.id_ = UUID()
                newForest.name_ = trimmedName
                newForest.description_ = trimmedDescription
                newForest.creationDate_ = Date()
                newForest.order_ = 0
                dataController.save()
                print("✅ Created new forest: \(trimmedName)")
            }
            
            dismiss()
        } catch {
            alertMessage = "Failed to save forest: \(error.localizedDescription)"
            showingAlert = true
            print("❌ Error saving forest: \(error)")
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateForestCompletion(for forest: Forest) -> Double {
        let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
        guard !trees.isEmpty else { return 0.0 }
        let totalCompletion = trees.reduce(0.0) { sum, tree in
            sum + tree.completionPercentage
        }
        return totalCompletion / Double(trees.count)
    }
    
    private func calculateTotalTreesCount(for forest: Forest) -> Int {
        let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
        return trees.count
    }
    
    private func calculateTotalNodesCount(for forest: Forest) -> Int {
        let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
        return trees.reduce(0) { sum, tree in
            sum + tree.totalNodesCount
        }
    }
}

#Preview {
    EditForestView()
        .environmentObject(DataController.preview)
} 