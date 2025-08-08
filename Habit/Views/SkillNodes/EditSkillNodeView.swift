import SwiftUI

struct EditSkillNodeView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var nodeType: SkillNodeType = .goal
    @State private var selectedHabit: Habit?
    @State private var selectedParent: SkillNode?
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
            _selectedParent = State(initialValue: node.parentNode)
        }
    }
    
    var isEditing: Bool {
        skillNode != nil
    }
    
    var availableHabits: [Habit] {
        dataController.getAllHabits()
    }
    
    var availableParentNodes: [SkillNode] {
        let allNodes = skillTree.nodes
        guard let currentNode = skillNode else {
            // For new nodes, all nodes are available as parents (including root)
            return allNodes.sorted { $0.name < $1.name }
        }
        
        // For existing nodes, exclude the current node and all its descendants
        let descendants = currentNode.getAllDescendants()
        let excludedNodes = Set([currentNode] + descendants)
        
        return allNodes
            .filter { !excludedNodes.contains($0) } // Don't exclude root nodes
            .sorted { $0.name < $1.name }
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
            
            Section {
                Picker("Parent Node", selection: $selectedParent) {
                    // Allow clearing parent (making node a root) only when editing
                    if isEditing {
                        Text("No parent (make root)")
                            .tag(nil as SkillNode?)
                    }
                    ForEach(availableParentNodes) { parentNode in
                        HStack {
                            Image(systemName: parentNode.nodeType.icon)
                                .foregroundColor(.blue)
                            Text(parentNode.name)
                        }
                        .tag(parentNode as SkillNode?)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Parent Node")
            } footer: {
                Text("Select a parent node. All nodes must have a parent except the root node.")
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
        
        // For new nodes, require a parent
        if skillNode == nil && selectedParent == nil {
            alertMessage = "Please select a parent node. All nodes must have a parent."
            showingAlert = true
            return
        }
        
        do {
            if let existingNode = skillNode {
                // Update existing node
                existingNode.name = trimmedName
                existingNode.nodeDescription = trimmedDescription
                existingNode.nodeType = nodeType
                
                // Handle parent relationship (can change parent, including to root)
                dataController.moveNodeToNewParent(node: existingNode, newParent: selectedParent)
                
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
                // Create new node (parent is required)
                let newNode = dataController.createSkillNode(name: trimmedName, type: nodeType, description: trimmedDescription, in: skillTree)
                
                // Add to selected parent (required)
                if let selectedParent = selectedParent {
                    dataController.addChildToParent(child: newNode, parent: selectedParent)
                }
                
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