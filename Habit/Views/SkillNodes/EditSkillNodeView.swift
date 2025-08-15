import SwiftUI

struct EditSkillNodeView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var nodeType: SkillNodeType = .goal
    @State private var selectedHabit: Habit?
    @State private var selectedParent: SkillNode?
    @State private var selectedLevel: Int = 1
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false
    
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
            _selectedLevel = State(initialValue: node.level)
        }
    }
    
    var isEditing: Bool {
        skillNode != nil
    }
    
    var availableHabits: [Habit] {
        dataController.getAllHabits()
    }
    
    var availableParentNodes: [SkillNode] {
        // Ensure root node exists for the selected level before getting nodes
        skillTree.ensureRootNodeExists(for: selectedLevel)
        
        // Only show nodes from the same level as the selected level
        let levelNodes = skillTree.getNodesForLevel(selectedLevel)
        
        guard let currentNode = skillNode else {
            // For new nodes, show all nodes from the selected level
            return levelNodes.sorted { $0.name < $1.name }
        }
        
        // For existing nodes, exclude the current node and all its descendants
        let descendants = currentNode.getAllDescendants()
        let excludedNodes = Set([currentNode] + descendants)
        
        return levelNodes
            .filter { !excludedNodes.contains($0) }
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
            
            Section {
                Picker("Level", selection: $selectedLevel) {
                    ForEach(1...skillTree.maxLevel, id: \.self) { level in
                        HStack {
                            Image(systemName: level <= skillTree.currentLevel ? "lock.open.fill" : "lock.fill")
                                .foregroundColor(level <= skillTree.currentLevel ? .green : .orange)
                            Text("Level \(level)")
                            if level == skillTree.currentLevel {
                                Text("(Current)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            } else if level > skillTree.currentLevel {
                                Text("(Locked)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .tag(level)
                    }
                    
                    // Allow creating nodes for future levels
                    if selectedLevel > skillTree.maxLevel {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                            Text("Level \(selectedLevel)")
                            Text("(New Level)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .tag(selectedLevel)
                    }
                    
                    // Add option to create a new level
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                        Text("Level \(skillTree.maxLevel + 1)")
                        Text("(Create New)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .tag(skillTree.maxLevel + 1)
                }
                .pickerStyle(.navigationLink)
                .onChange(of: selectedLevel) { newValue in
                    // When level changes, ensure root node exists and auto-select it as parent
                    skillTree.ensureRootNodeExists(for: newValue)
                    
                    // Auto-select the root node of the new level as the parent
                    let rootNode = skillTree.getRootNodeForLevel(newValue)
                    selectedParent = rootNode
                }
            } header: {
                Text("Level")
            } footer: {
                Text("Choose which level this node belongs to. Level \(skillTree.currentLevel) is currently unlocked. Higher levels will be locked until previous levels are completed.")
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

                // Large destructive button
                Section {
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Text("Delete Node")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Create/Save Button Section
            Section {
                Button(isEditing ? "Save" : "Create") {
                    saveSkillNode()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle(isEditing ? "Edit Node" : "New Node")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // For new nodes, auto-select the root node as parent if no parent is selected
            if skillNode == nil && selectedParent == nil {
                skillTree.ensureRootNodeExists(for: selectedLevel)
                selectedParent = skillTree.getRootNodeForLevel(selectedLevel)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Delete Node", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSkillNode()
            }
        } message: {
            Text("Are you sure you want to delete this node? This action cannot be undone.")
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
                existingNode.level = selectedLevel
                
                // Update tree's maxLevel if this node is in a higher level
                if selectedLevel > skillTree.maxLevel {
                    skillTree.maxLevel = selectedLevel
                    // Ensure root node exists for this new level
                    skillTree.ensureRootNodeExists(for: selectedLevel)
                }
                
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
                newNode.level = selectedLevel
                
                // Update tree's maxLevel if this node is in a higher level
                if selectedLevel > skillTree.maxLevel {
                    skillTree.maxLevel = selectedLevel
                    // Ensure root node exists for this new level
                    skillTree.ensureRootNodeExists(for: selectedLevel)
                }
                
                // Add to selected parent (required)
                if let selectedParent = selectedParent {
                    dataController.addChildToParent(child: newNode, parent: selectedParent)
                }
                
                // Handle habit linking for new node
                if nodeType == .habitLinked, let selectedHabit = selectedHabit {
                    newNode.linkToHabit(selectedHabit)
                }
                
                dataController.save()
            }
            
            dismiss()
        }
    }

    private func deleteSkillNode() {
        guard let node = skillNode else { return }
        dataController.deleteSkillNode(node)
        dismiss()
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