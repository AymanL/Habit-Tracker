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
    
    var rootNode: SkillNode? {
        skillTree.nodes.filter { $0.isRootNode }.sorted { $0.order < $1.order }.first
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Tree Structure")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Single root node tree visualization
            if let root = rootNode {
                NestedNodeView(node: root, onNodeTap: onNodeTap)
            } else {
                Text("No root node found")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.vertical)
    }
}

struct NestedNodeView: View {
    @ObservedObject var node: SkillNode
    let onNodeTap: (SkillNode) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Current node
            SkillNodeVisualView(node: node) {
                onNodeTap(node)
            }
            
            // Children (if any) - evenly spaced horizontally
            if node.hasChildren {
                let sortedChildren = Array(node.childNodes).sorted(by: { $0.order < $1.order })
                
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(sortedChildren, id: \.id) { childNode in
                                NestedNodeView(node: childNode, onNodeTap: onNodeTap)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Scroll indicators - more robust calculation
                    HStack {
                        // Left arrow (when can scroll left)
                        if shouldShowScrollIndicators(for: sortedChildren) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color(.systemBackground).opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        
                        Spacer()
                        
                        // Right arrow (when can scroll right)
                        if shouldShowScrollIndicators(for: sortedChildren) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color(.systemBackground).opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .border(Color.red, width: 2)
    }
    
    // Helper function to determine if scroll indicators should be shown
    private func shouldShowScrollIndicators(for children: [SkillNode]) -> Bool {
        // Calculate total visual width needed
        let estimatedNodeWidth: CGFloat = 120 // Base width for a node
        let spacing: CGFloat = 20
        let totalWidthNeeded = CGFloat(children.count) * estimatedNodeWidth + CGFloat(children.count - 1) * spacing
        
        // Account for nodes with many descendants (they take more space)
        let totalDescendants = children.reduce(0) { count, child in
            count + child.getAllDescendants().count
        }
        
        // If there are many descendants, we likely need scrolling
        let hasManyDescendants = totalDescendants > children.count * 2
        
        // Show indicators if we have many children OR many descendants
        return children.count > 4 || hasManyDescendants || totalWidthNeeded > 400
    }
}



struct HierarchicalNodeView: View {
    @ObservedObject var node: SkillNode
    let onTap: (SkillNode) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Node with indentation based on depth
            HStack(spacing: 0) {
                // Indentation
                ForEach(0..<node.depth, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 20, height: 1)
                        .padding(.leading, 8)
                }
                
                // Node content
                SkillNodeVisualView(node: node) {
                    onTap(node)
                }
                .padding(.leading, node.depth > 0 ? 8 : 0)
                
                Spacer()
            }
            
            // Children (if any)
            if node.hasChildren {
                VStack(spacing: 0) {
                    ForEach(Array(node.childNodes.sorted(by: { $0.order < $1.order })), id: \.id) { childNode in
                        HierarchicalNodeView(node: childNode, onTap: onTap)
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
                // Node icon
                ZStack {
                    let dailyStatus = node.getDailyCompletionStatus()
                    Circle()
                        .fill(dailyStatus == .notCompleted ? Color.blue : Color.green)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: nodeTypeIcon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                // Node title
                Text(node.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 80)
            .padding(.vertical, 8)
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