import SwiftUI

struct EditSkillTreeView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var withSampleNodes = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let skillTree: SkillTree?
    
    init(skillTree: SkillTree? = nil) {
        self.skillTree = skillTree
        if let tree = skillTree {
            _name = State(initialValue: tree.name)
            _description = State(initialValue: tree.treeDescription)
        }
    }
    
    var isEditing: Bool {
        skillTree != nil
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Skill Tree Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Description (Optional)", text: $description, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            } header: {
                Text("Tree Information")
            } footer: {
                Text("Give your skill tree a descriptive name and optional description to help you remember its purpose.")
            }
            
            if !isEditing {
                Section {
                    Toggle("Add Sample Nodes", isOn: $withSampleNodes)
                } header: {
                    Text("Quick Start")
                } footer: {
                    Text("Add some example nodes to get started quickly. You can edit or delete them later.")
                }
            }
            
            if isEditing {
                Section {
                    HStack {
                        Label("Created", systemImage: "calendar")
                        Spacer()
                        Text(skillTree?.creationDate.formatted(date: .abbreviated, time: .omitted) ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Nodes", systemImage: "circle.grid.2x2")
                        Spacer()
                        Text("\(skillTree?.nodes.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                        Spacer()
                        Text("\(Int((skillTree?.completionPercentage ?? 0) * 100))%")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Tree Statistics")
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Skill Tree" : "New Skill Tree")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Create") {
                    saveSkillTree()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveSkillTree() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter a name for the skill tree."
            showingAlert = true
            return
        }
        
        do {
            if let existingTree = skillTree {
                // Update existing tree
                existingTree.name = trimmedName
                existingTree.treeDescription = trimmedDescription
                dataController.save()
            } else {
                // Create new tree
                _ = dataController.createSkillTree(name: trimmedName, description: trimmedDescription, withSampleNodes: withSampleNodes)
            }
            
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        EditSkillTreeView()
    }
    .environmentObject(DataController.preview)
} 