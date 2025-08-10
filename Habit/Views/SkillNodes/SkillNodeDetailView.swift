import SwiftUI

// Deprecated wrapper – kept to avoid project churn; route directly to EditSkillNodeView.
@available(*, deprecated, message: "Use EditSkillNodeView directly")
struct SkillNodeDetailView: View {
    @ObservedObject var skillNode: SkillNode
    var body: some View {
        if let tree = skillNode.tree {
            EditSkillNodeView(skillTree: tree, skillNode: skillNode)
        } else {
            Text("Missing tree context")
        }
    }
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
                
                // Root node indicator
                if skillNode.isRootNode {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text("Root Node")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
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
        case .root:
            return "star.fill"
        case .goal:
            return "target"
        case .activity:
            return "repeat"
        case .habitLinked:
            return "link"
        case .boss:
            return "crown.fill"
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
                if skillNode.nodeType != .root {
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
        let ctx = DataController.preview.container.viewContext
        let tree = SkillTree(context: ctx, name: "Preview Tree")
        EditSkillNodeView(skillTree: tree, skillNode: SkillNode(context: ctx, name: "Sample Node", type: .activity, description: "This is a sample node"))
    }
    .environmentObject(DataController.preview)
} 