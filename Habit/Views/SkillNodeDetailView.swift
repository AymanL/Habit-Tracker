import SwiftUI

struct SkillNodeDetailView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var skillNode: SkillNode
    @State private var showingDeleteAlert = false
    
    // Debug state tracking
    @State private var debugInfo: String = ""
    @State private var lastUpdateTime = Date()
    @State private var debugPanelVisible = true // Force debug panel to stay visible
    @State private var debugTimer: Timer?
    
    // Meta-debugging for the debug panel itself
    @State private var debugPanelAppearCount = 0
    @State private var debugPanelDisappearCount = 0
    @State private var lastDebugPanelChange = Date()
    @State private var debugPanelChangeReason = "Initial"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Always visible debug indicator (for testing)
                #if DEBUG
                HStack {
                    Text("🔍 DEBUG MODE")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Text("Panel: \(debugPanelVisible ? "ON" : "OFF")")
                        .font(.caption)
                        .foregroundColor(debugPanelVisible ? .green : .orange)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
                #endif
                
                // Debug info (always show in debug builds)
                #if DEBUG
                if debugPanelVisible {
                    DebugNodeInfoView(skillNode: skillNode)
                    
                    // Additional debug panel
                    VStack(spacing: 8) {
                        HStack {
                            Text("View Debug Info")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Hide") {
                                debugPanelChangeReason = "Manual Hide"
                                lastDebugPanelChange = Date()
                                debugPanelVisible = false
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Update: \(lastUpdateTime, style: .time)")
                                .font(.caption)
                            Text("Node Deleted: \(skillNode.isDeleted ? "Yes" : "No")")
                                .font(.caption)
                            Text("Has Context: \(skillNode.managedObjectContext != nil ? "Yes" : "No")")
                                .font(.caption)
                            Text("Has Changes: \(skillNode.hasChanges ? "Yes" : "No")")
                                .font(.caption)
                            Text("Object ID: \(skillNode.objectID.uriRepresentation().absoluteString)")
                                .font(.caption)
                                .lineLimit(1)
                            Text("Node Name: \(skillNode.name)")
                                .font(.caption)
                            Text("Node Type: \(skillNode.nodeType.displayName)")
                                .font(.caption)
                            
                            // Meta-debugging info
                            Divider()
                            Text("🔍 META-DEBUG INFO:")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("Panel Appear Count: \(debugPanelAppearCount)")
                                .font(.caption)
                            Text("Panel Disappear Count: \(debugPanelDisappearCount)")
                                .font(.caption)
                            Text("Last Change: \(lastDebugPanelChange, style: .time)")
                                .font(.caption)
                            Text("Change Reason: \(debugPanelChangeReason)")
                                .font(.caption)
                            Text("Panel Visible: \(debugPanelVisible ? "Yes" : "No")")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .onAppear {
                        debugPanelAppearCount += 1
                        debugPanelChangeReason = "Panel Appeared"
                        lastDebugPanelChange = Date()
                        print("🔍 DEBUG PANEL APPEARED - Count: \(debugPanelAppearCount)")
                    }
                    .onDisappear {
                        debugPanelDisappearCount += 1
                        debugPanelChangeReason = "Panel Disappeared"
                        lastDebugPanelChange = Date()
                        print("🔍 DEBUG PANEL DISAPPEARED - Count: \(debugPanelDisappearCount)")
                    }
                } else {
                    Button("Show Debug Panel") {
                        debugPanelChangeReason = "Manual Show"
                        lastDebugPanelChange = Date()
                        debugPanelVisible = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                #endif
                
                // Node header
                SkillNodeHeaderView(skillNode: skillNode)
                
                // Node details
                SkillNodeDetailsView(skillNode: skillNode)
                
                // Linked habit info
                if skillNode.nodeType == .habitLinked {
                    if let habit = skillNode.habit {
                        LinkedHabitView(habit: habit)
                    } else {
                        // Show error state for unlinked habit nodes
                        UnlinkedHabitView()
                    }
                }
                
                // Action buttons
                SkillNodeActionsView(skillNode: skillNode)
            }
            .padding()
        }
        .navigationTitle(skillNode.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    NavigationLink(destination: {
                        if let tree = skillNode.tree {
                            EditSkillNodeView(skillTree: tree, skillNode: skillNode)
                        }
                    }) {
                        Label("Edit Node", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Node", systemImage: "trash")
                    }
                    
                    #if DEBUG
                    Button(action: refreshDebugInfo) {
                        Label("Refresh Debug", systemImage: "arrow.clockwise")
                    }
                    
                    Button(action: { debugPanelVisible.toggle() }) {
                        Label(debugPanelVisible ? "Hide Debug" : "Show Debug", systemImage: "info.circle")
                    }
                    #endif
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Node", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteNode()
            }
        } message: {
            Text("Are you sure you want to delete this node? This action cannot be undone.")
        }
        .onAppear {
            logViewAppearance()
            // Ensure debug panel is visible on appear
            debugPanelVisible = true
            
            #if DEBUG
            // Start a timer to monitor node state
            debugTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                checkNodeValidity()
            }
            
            print("🔍 MAIN VIEW APPEARED - Debug Panel Visible: \(debugPanelVisible)")
            #endif
        }
        .onDisappear {
            #if DEBUG
            debugTimer?.invalidate()
            debugTimer = nil
            print("🔍 MAIN VIEW DISAPPEARED")
            #endif
        }
        .onChange(of: skillNode) { _ in
            logNodeChange()
            print("🔄 SKILL NODE CHANGED - Debug Panel Visible: \(debugPanelVisible)")
        }
        .onChange(of: skillNode.isDeleted) { isDeleted in
            print("🔄 Node deletion status changed: \(isDeleted)")
            if isDeleted {
                print("⚠️ Node was deleted, view may become invalid")
            }
        }
        .onChange(of: debugPanelVisible) { isVisible in
            print("🔄 DEBUG PANEL VISIBILITY CHANGED: \(isVisible)")
            print("   Reason: \(debugPanelChangeReason)")
            print("   Time: \(Date())")
        }
    }
    
    private func deleteNode() {
        dataController.deleteSkillNode(skillNode)
        dismiss()
    }
    
    #if DEBUG
    private func refreshDebugInfo() {
        lastUpdateTime = Date()
        logViewAppearance()
        print("🔄 Debug info refreshed at \(lastUpdateTime)")
    }
    
    private func logViewAppearance() {
        print("🔍 SkillNodeDetailView appeared")
        print("   Node: \(skillNode.name)")
        print("   Deleted: \(skillNode.isDeleted)")
        print("   Context: \(skillNode.managedObjectContext != nil)")
        print("   Has Changes: \(skillNode.hasChanges)")
        print("   Object ID: \(skillNode.objectID.uriRepresentation().absoluteString)")
        print("   Debug Panel Visible: \(debugPanelVisible)")
        
        if let tree = skillNode.tree {
            print("   Tree: \(tree.name)")
        } else {
            print("   Tree: nil")
        }
        
        if let habit = skillNode.habit {
            print("   Habit: \(habit.title)")
        } else {
            print("   Habit: nil")
        }
    }
    
    private func logNodeChange() {
        print("🔄 SkillNodeDetailView node changed")
        print("   Node: \(skillNode.name)")
        print("   Deleted: \(skillNode.isDeleted)")
        print("   Debug Panel Visible: \(debugPanelVisible)")
        lastUpdateTime = Date()
    }
    
    private func checkNodeValidity() {
        print("🔍 Checking node validity...")
        print("   Node deleted: \(skillNode.isDeleted)")
        print("   Node has context: \(skillNode.managedObjectContext != nil)")
        print("   Node name: \(skillNode.name)")
        print("   Object ID: \(skillNode.objectID.uriRepresentation().absoluteString)")
    }
    #endif
}

struct SkillNodeHeaderView: View {
    @ObservedObject var skillNode: SkillNode
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(skillNode.isCompleted ? Color.green : Color.blue)
                    .frame(width: 80, height: 80)
                
                Image(systemName: nodeTypeIcon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(skillNode.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if !skillNode.nodeDescription.isEmpty {
                    Text(skillNode.nodeDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Text(skillNode.nodeType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                let dailyStatus = skillNode.getDailyCompletionStatus()
                HStack(spacing: 4) {
                    Image(systemName: dailyStatus.icon)
                        .foregroundColor(dailyStatus.color)
                        .font(.caption)
                    
                    Text(dailyStatus.displayName)
                        .font(.caption)
                        .foregroundColor(dailyStatus.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(dailyStatus.color.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var nodeTypeIcon: String {
        switch skillNode.nodeType {
        case .goal:
            return "target"
        case .activity:
            return "repeat"
        case .habitLinked:
            return "link"
        }
    }
}

struct SkillNodeDetailsView: View {
    @ObservedObject var skillNode: SkillNode
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Node Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                DetailRow(
                    icon: "calendar",
                    title: "Created",
                    value: skillNode.creationDate.formatted(date: .abbreviated, time: .omitted)
                )
                
                DetailRow(
                    icon: "checkmark.circle",
                    title: "Status",
                    value: skillNode.isCompleted ? "Completed" : "Not Completed",
                    valueColor: skillNode.isCompleted ? .green : .secondary
                )
                
                DetailRow(
                    icon: "calendar.badge.clock",
                    title: "Today's Status",
                    value: skillNode.getDailyCompletionStatus().displayName,
                    valueColor: skillNode.getDailyCompletionStatus().color
                )
                
                if let completionDate = skillNode.completionDate {
                    DetailRow(
                        icon: "calendar.badge.clock",
                        title: "Completed On",
                        value: completionDate.formatted(date: .abbreviated, time: .omitted)
                    )
                }
                
                DetailRow(
                    icon: "tree",
                    title: "Skill Tree",
                    value: skillNode.tree?.name ?? "Unknown"
                )
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .secondary
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct LinkedHabitView: View {
    let habit: Habit
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Linked Habit")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(habit.color))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if !habit.motivation.isEmpty {
                        Text(habit.motivation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("0")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("completions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct UnlinkedHabitView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Linked Habit")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("No Habit Linked")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Text("This node is configured as habit-linked but no habit is connected. Edit the node to link it to a habit.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct DebugNodeInfoView: View {
    @ObservedObject var skillNode: SkillNode
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Debug Info")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                DebugRow(title: "Node ID", value: skillNode.id.uuidString)
                DebugRow(title: "Node Type", value: skillNode.nodeType.displayName)
                DebugRow(title: "Is Completed", value: skillNode.isCompleted ? "Yes" : "No")
                DebugRow(title: "Has Habit", value: skillNode.habit != nil ? "Yes" : "No")
                if let habit = skillNode.habit {
                    DebugRow(title: "Habit Title", value: habit.title)
                    DebugRow(title: "Habit ID", value: habit.id.uuidString)
                }
                DebugRow(title: "Has Tree", value: skillNode.tree != nil ? "Yes" : "No")
                if let tree = skillNode.tree {
                    DebugRow(title: "Tree Name", value: tree.name)
                    DebugRow(title: "Tree ID", value: tree.id.uuidString)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DebugRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct SkillNodeActionsView: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var skillNode: SkillNode
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                let dailyStatus = skillNode.getDailyCompletionStatus()
                
                if dailyStatus == .notCompleted {
                    Button(action: completeNodeForToday) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Completed for Today")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    Button(action: uncompleteNodeForToday) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Mark as Not Completed for Today")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                if skillNode.nodeType == .habitLinked && skillNode.habit != nil {
                    Button(action: openLinkedHabit) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("View Linked Habit")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func completeNodeForToday() {
        skillNode.completeForToday()
        dataController.save()
    }
    
    private func uncompleteNodeForToday() {
        skillNode.uncompleteForToday()
        dataController.save()
    }
    
    private func openLinkedHabit() {
        // TODO: Navigate to habit detail view
        print("Open linked habit: \(skillNode.habit?.title ?? "Unknown")")
    }
}

#Preview {
    NavigationView {
        SkillNodeDetailView(
            skillNode: SkillNode(context: DataController.preview.container.viewContext, name: "Sample Node", type: .goal, description: "This is a sample node")
        )
    }
    .environmentObject(DataController.preview)
} 