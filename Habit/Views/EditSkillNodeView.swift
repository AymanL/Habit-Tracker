import SwiftUI

struct EditSkillNodeView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var nodeType: SkillNodeType = .goal
    @State private var selectedHabit: Habit?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let skillTree: SkillTree
    let skillNode: SkillNode?
    
    init(skillTree: SkillTree, skillNode: SkillNode? = nil) {
        self.skillTree = skillTree
        self.skillNode = skillNode
        if let node = skillNode {
            _name = State(initialValue: node.name)
            _description = State(initialValue: node.nodeDescription)
            _nodeType = State(initialValue: node.nodeType)
            _selectedHabit = State(initialValue: node.habit)
        }
    }
    
    var isEditing: Bool {
        skillNode != nil
    }
    
    var availableHabits: [Habit] {
        dataController.getAllHabits()
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Node Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Description (Optional)", text: $description, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            } header: {
                Text("Node Information")
            } footer: {
                Text("Give your node a clear name and optional description.")
            }
            
            Section {
                Picker("Node Type", selection: $nodeType) {
                    ForEach(SkillNodeType.allCases, id: \.self) { type in
                        VStack(alignment: .leading) {
                            Text(type.displayName)
                                .font(.body)
                            Text(type.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Node Type")
            } footer: {
                Text("Choose the type of node based on how it should be completed.")
            }
            
            if nodeType == .habitLinked {
                Section {
                    if availableHabits.isEmpty {
                        Text("No habits available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Picker("Linked Habit", selection: $selectedHabit) {
                            Text("Select a habit...")
                                .tag(nil as Habit?)
                            
                            ForEach(availableHabits) { habit in
                                HStack {
                                    Circle()
                                        .fill(Color(habit.color))
                                        .frame(width: 12, height: 12)
                                    Text(habit.title)
                                }
                                .tag(habit as Habit?)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                } header: {
                    Text("Linked Habit")
                } footer: {
                    Text("Select an existing habit to link this node to. The node will be completed when the habit is completed.")
                }
            }
            
            if isEditing {
                Section {
                    HStack {
                        Label("Created", systemImage: "calendar")
                        Spacer()
                        Text(skillNode?.creationDate.formatted(date: .abbreviated, time: .omitted) ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Status", systemImage: "checkmark.circle")
                        Spacer()
                        Text(skillNode?.isCompleted == true ? "Completed" : "Not Completed")
                            .foregroundColor(skillNode?.isCompleted == true ? .green : .secondary)
                    }
                    
                    if let completionDate = skillNode?.completionDate {
                        HStack {
                            Label("Completed On", systemImage: "calendar.badge.clock")
                            Spacer()
                            Text(completionDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Node Statistics")
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Node" : "New Node")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Create") {
                    saveSkillNode()
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
    
    private func saveSkillNode() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter a name for the node."
            showingAlert = true
            return
        }
        
        if nodeType == .habitLinked && selectedHabit == nil {
            alertMessage = "Please select a habit to link this node to."
            showingAlert = true
            return
        }
        
        do {
            if let existingNode = skillNode {
                // Update existing node
                existingNode.name = trimmedName
                existingNode.nodeDescription = trimmedDescription
                existingNode.nodeType = nodeType
                
                // Handle habit linking
                if nodeType == .habitLinked {
                    if let selectedHabit = selectedHabit {
                        existingNode.linkToHabit(selectedHabit)
                    } else {
                        existingNode.unlinkHabit()
                    }
                } else {
                    existingNode.unlinkHabit()
                }
                
                dataController.save()
            } else {
                // Create new node
                let newNode = dataController.createSkillNode(name: trimmedName, type: nodeType, description: trimmedDescription, in: skillTree)
                
                // Handle habit linking for new node
                if nodeType == .habitLinked, let selectedHabit = selectedHabit {
                    newNode.linkToHabit(selectedHabit)
                }
            }
            
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        EditSkillNodeView(
            skillTree: SkillTree(context: DataController.preview.container.viewContext, name: "Sample Tree", description: "A sample skill tree")
        )
    }
    .environmentObject(DataController.preview)
} 