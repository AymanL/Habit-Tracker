import SwiftUI

struct ForestDetailView: View {
    @ObservedObject var forest: Forest
    @EnvironmentObject var dataController: DataController
    @State private var showingAddTree = false
    @State private var selectedTree: SkillTree?
    @State private var showingTreeDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with forest info
                ForestHeaderView(forest: forest)
                
                // Trees visualization
                ForestTreesView(forest: forest) { tree in
                    selectedTree = tree
                    showingTreeDetail = true
                }
            }
            .padding()
        }
        .navigationTitle(forest.name_ ?? "Forest")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTree = true }) {
                    Label("Add Tree", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTree) {
            NavigationView {
                EditSkillTreeView(forest: forest)
            }
        }
        .background(
            Group {
                if let tree = selectedTree {
                    NavigationLink(
                        destination: SkillTreeDetailView(skillTree: tree),
                        isActive: $showingTreeDetail
                    ) {
                        EmptyView()
                    }
                }
            }
        )
    }
}

struct ForestHeaderView: View {
    @ObservedObject var forest: Forest
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(forest.name_ ?? "Forest")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !(forest.description_ ?? "").isEmpty {
                        Text(forest.description_ ?? "")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(calculateForestCompletion(forest) * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: calculateForestCompletion(forest))
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.green)
            
            HStack {
                Label("\(calculateCompletedTreesCount(forest)) completed", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Label("\(calculateTotalTreesCount(forest)) trees", systemImage: "tree")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(calculateTotalNodesCount(forest)) nodes", systemImage: "circle.grid.2x2")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ForestTreesView: View {
    @ObservedObject var forest: Forest
    let onTreeTap: (SkillTree) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Trees")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 12) {
                ForEach(getTreesSortedByOrder(forest), id: \.id) { tree in
                    ForestTreeRowView(tree: tree) {
                        onTreeTap(tree)
                    }
                }
            }
        }
    }
}

struct ForestTreeRowView: View {
    @ObservedObject var tree: SkillTree
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tree.completionPercentage == 1.0 ? Color.green : Color.blue)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "tree")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tree.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if !tree.treeDescription.isEmpty {
                        Text(tree.treeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        Text("\(tree.completedNodesCount)/\(tree.totalNodesCount) nodes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(tree.completionPercentage * 100))%")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        Text("Forest Detail View")
            .navigationTitle("Example Forest")
    }
    .environmentObject(DataController.preview)
}

// Helper functions for Forest properties (temporary until Core Data generates the class properly)
private func calculateForestCompletion(_ forest: Forest) -> Double {
    let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
    guard !trees.isEmpty else { return 0.0 }
    let totalCompletion = trees.reduce(0.0) { sum, tree in
        sum + tree.completionPercentage
    }
    return totalCompletion / Double(trees.count)
}

private func calculateCompletedTreesCount(_ forest: Forest) -> Int {
    let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
    return trees.filter { $0.completionPercentage == 1.0 }.count
}

private func calculateTotalTreesCount(_ forest: Forest) -> Int {
    let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
    return trees.count
}

private func calculateTotalNodesCount(_ forest: Forest) -> Int {
    let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
    return trees.reduce(0) { sum, tree in
        sum + tree.totalNodesCount
    }
}

private func getTreesSortedByOrder(_ forest: Forest) -> [SkillTree] {
    let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
    return trees.sorted { $0.order < $1.order }
} 