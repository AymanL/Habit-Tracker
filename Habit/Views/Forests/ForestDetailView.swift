import SwiftUI

struct ForestDetailView: View {
    @ObservedObject var forest: Forest
    @EnvironmentObject var dataController: DataController
    @State private var showingAddTree = false
    @State private var showingImportView = false
    @State private var selectedTree: SkillTree?
    @State private var showingTreeDetail = false
    @State private var currentTreeIndex = 0
    
    var sortedTrees: [SkillTree] {
        getTreesSortedByOrder(forest)
    }
    
    var currentTree: SkillTree? {
        guard !sortedTrees.isEmpty, currentTreeIndex < sortedTrees.count else { return nil }
        return sortedTrees[currentTreeIndex]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with forest info
                ForestHeaderView(forest: forest)
                
                // Tree navigation and display
                if !sortedTrees.isEmpty {
                    ForestTreeNavigationView(
                        forest: forest,
                        currentTree: currentTree,
                        currentIndex: currentTreeIndex,
                        totalTrees: sortedTrees.count,
                        onPrevious: previousTree,
                        onNext: nextTree,
                        onTreeTap: { tree in
                            selectedTree = tree
                            showingTreeDetail = true
                        }
                    )
                } else {
                    // No trees message
                    VStack(spacing: 16) {
                        Image(systemName: "tree")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Trees Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Add your first tree to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddTree = true }) {
                        Label("Add Tree", systemImage: "plus")
                    }
                    
                    Button(action: { showingImportView = true }) {
                        Label("Import Tree", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddTree) {
            NavigationView {
                EditSkillTreeView(forest: forest)
            }
        }
        .sheet(isPresented: $showingImportView) {
            ImportSingleTreeView(forest: forest)
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
    
    private func previousTree() {
        guard !sortedTrees.isEmpty else { return }
        currentTreeIndex = (currentTreeIndex - 1 + sortedTrees.count) % sortedTrees.count
    }
    
    private func nextTree() {
        guard !sortedTrees.isEmpty else { return }
        currentTreeIndex = (currentTreeIndex + 1) % sortedTrees.count
    }
}

// MARK: - Forest Header View
struct ForestHeaderView: View {
    @ObservedObject var forest: Forest
    @State private var progressRefreshTick: Int = 0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Forest title brought back into the header area
                Text(forest.name_ ?? "Forest")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(calculateForestCompletion(forest) * 100))%")
                        .font(.headline)
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
                .id(progressRefreshTick)
            
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
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: forest.managedObjectContext)) { _ in
            progressRefreshTick &+= 1
        }
    }
}

// MARK: - Forest Tree Navigation View
struct ForestTreeNavigationView: View {
    @ObservedObject var forest: Forest
    let currentTree: SkillTree?
    let currentIndex: Int
    let totalTrees: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onTreeTap: (SkillTree) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Current tree display
            if let tree = currentTree {
                ForestTreeDisplayView(
                    tree: tree,
                    canNavigate: totalTrees > 1,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onTreeTap: onTreeTap
                )
                ForestTreeDisplayView(
                    tree: tree,
                    canNavigate: totalTrees > 1,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onTreeTap: onTreeTap
                )
            }
        }
    }
}

// MARK: - Forest Tree Display View
struct ForestTreeDisplayView: View {
    @ObservedObject var tree: SkillTree
    let canNavigate: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let canNavigate: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onTreeTap: (SkillTree) -> Void
    @State private var selectedNode: SkillNode?
    @State private var showingNodeDetail = false
    @State private var showingAddNode = false
    @State private var levelHeights: [Int: CGFloat] = [:]
    @State private var progressRefreshTick: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Tree header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tree.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .font(.headline)
                        .fontWeight(.semibold)
                    if !tree.treeDescription.isEmpty {
                        Text(tree.treeDescription)
                            .font(.caption)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Text("\(Int(tree.completionPercentage * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .id(progressRefreshTick)
            }
            
            // Progress bar with navigation and add button
            HStack(spacing: 8) {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canNavigate)
                
                ProgressView(value: tree.completionPercentage)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.green)
                    .frame(maxWidth: .infinity)
                    .id(progressRefreshTick)
                
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canNavigate)
                
                Button(action: { showingAddNode = true }) {
                    Image(systemName: "plus.circle")
                }
            }
            
            // Tree stats
            HStack {
                Label("\(tree.completedNodesCount)/\(tree.totalNodesCount) nodes", systemImage: "circle.grid.2x2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(tree.completedNodesCount) completed", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            // Tree visualization
            if let rootNode = tree.rootNodes.first {
                VStack(alignment: .leading, spacing: 4) {
                    NestedNodeView(node: rootNode) { node in
                        selectedNode = node
                        showingNodeDetail = true
                    }
                    .environment(\.levelHeightMap, levelHeights)
                    .onPreferenceChange(LevelHeightPreferenceKey.self) { heights in
                        levelHeights = heights
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(maxWidth: 350)
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: tree.managedObjectContext)) { _ in
            progressRefreshTick &+= 1
        }
        .sheet(item: $selectedNode) { node in
            NavigationView {
                SkillNodeDetailView(skillNode: node)
            }
        }
        .sheet(isPresented: $showingAddNode) {
            NavigationView {
                EditSkillNodeView(skillTree: tree)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        Text("Forest Detail View")
            .navigationTitle("Example Forest")
    }
    .environmentObject(DataController.preview)
}

// MARK: - Helper Functions
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