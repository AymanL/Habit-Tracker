import SwiftUI

struct SkillTreeDetailView: View {
    @ObservedObject var skillTree: SkillTree
    @EnvironmentObject var dataController: DataController
    @State private var showingAddNode = false
    @State private var selectedNode: SkillNode?
    @State private var showingNodeDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with tree info
                SkillTreeHeaderView(skillTree: skillTree)
                
                // Tree visualization
                SkillTreeVisualizationView(skillTree: skillTree) { node in
                    selectedNode = node
                    showingNodeDetail = true
                }
                
                // Node list
                SkillTreeNodesListView(skillTree: skillTree) { node in
                    selectedNode = node
                    showingNodeDetail = true
                }
            }
            .padding()
        }
        .navigationTitle(skillTree.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddNode = true }) {
                    Label("Add Node", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddNode) {
            NavigationView {
                EditSkillNodeView(skillTree: skillTree)
            }
        }
        .background(
            Group {
                if let node = selectedNode {
                    NavigationLink(
                        destination: SkillNodeDetailView(skillNode: node),
                        isActive: $showingNodeDetail
                    ) {
                        EmptyView()
                    }
                }
            }
        )
    }
}

struct SkillTreeHeaderView: View {
    @ObservedObject var skillTree: SkillTree
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(skillTree.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !skillTree.treeDescription.isEmpty {
                        Text(skillTree.treeDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(skillTree.completionPercentage * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: skillTree.completionPercentage)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.green)
            
            HStack {
                Label("\(skillTree.completedNodesCount) completed", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Label("\(skillTree.totalNodesCount) total", systemImage: "circle.grid.2x2")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SkillTreeVisualizationView: View {
    @ObservedObject var skillTree: SkillTree
    let onNodeTap: (SkillNode) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Tree Structure")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Simple tree visualization
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(skillTree.nodes) { node in
                    SkillNodeVisualView(node: node) {
                        onNodeTap(node)
                    }
                }
            }
        }
    }
}

struct SkillNodeVisualView: View {
    @ObservedObject var node: SkillNode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    let dailyStatus = node.getDailyCompletionStatus()
                    Circle()
                        .fill(dailyStatus == .notCompleted ? Color.blue : Color.green)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: nodeTypeIcon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text(node.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if node.nodeType == .habitLinked {
                    let dailyStatus = node.getDailyCompletionStatus()
                    HStack(spacing: 2) {
                        Image(systemName: dailyStatus.icon)
                            .font(.caption2)
                            .foregroundColor(dailyStatus.color)
                        Text("Today")
                            .font(.caption2)
                            .foregroundColor(dailyStatus.color)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var nodeTypeIcon: String {
        switch node.nodeType {
        case .goal:
            return "target"
        case .activity:
            return "repeat"
        case .habitLinked:
            return "link"
        }
    }
}

struct SkillTreeNodesListView: View {
    @ObservedObject var skillTree: SkillTree
    let onNodeTap: (SkillNode) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("All Nodes")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 8) {
                ForEach(skillTree.nodes) { node in
                    SkillNodeRowView(node: node) {
                        onNodeTap(node)
                    }
                }
            }
        }
    }
}

struct SkillNodeRowView: View {
    @ObservedObject var node: SkillNode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(node.isCompleted ? Color.green : Color.blue)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: nodeTypeIcon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if !node.nodeDescription.isEmpty {
                        Text(node.nodeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 4) {
                        Text(node.nodeType.displayName)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        if node.nodeType == .habitLinked {
                            if node.habit != nil {
                                Text("Linked")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(4)
                            } else {
                                Text("Unlinked")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let dailyStatus = node.getDailyCompletionStatus()
                    
                    HStack(spacing: 4) {
                        Image(systemName: dailyStatus.icon)
                            .foregroundColor(dailyStatus.color)
                            .font(.caption)
                        
                        Text(dailyStatus.displayName)
                            .font(.caption)
                            .foregroundColor(dailyStatus.color)
                    }
                    
                    if node.nodeType == .habitLinked && node.habit != nil {
                        Text("Today")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var nodeTypeIcon: String {
        switch node.nodeType {
        case .goal:
            return "target"
        case .activity:
            return "repeat"
        case .habitLinked:
            return "link"
        }
    }
}

#Preview {
    NavigationView {
        SkillTreeDetailView(skillTree: SkillTree(context: DataController.preview.container.viewContext, name: "Sample Tree", description: "A sample skill tree"))
    }
    .environmentObject(DataController.preview)
} 