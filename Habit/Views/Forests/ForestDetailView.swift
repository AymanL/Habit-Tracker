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
        .navigationTitle(forest.name_ ?? "Forest")
        .navigationBarTitleDisplayMode(.large)
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
            // Navigation header
            HStack {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(totalTrees <= 1)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Tree \(currentIndex + 1) of \(totalTrees)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if let tree = currentTree {
                        Text(tree.name)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(totalTrees <= 1)
            }
            .padding(.horizontal)
            
            // Current tree display
            if let tree = currentTree {
                ForestTreeDisplayView(tree: tree, onTreeTap: onTreeTap)
            }
        }
    }
}

// MARK: - Forest Tree Display View
struct ForestTreeDisplayView: View {
    @ObservedObject var tree: SkillTree
    let onTreeTap: (SkillTree) -> Void
    @State private var selectedNode: SkillNode?
    @State private var showingNodeDetail = false
    @State private var showingAddNode = false
    @State private var levelHeights: [Int: CGFloat] = [:]
    
    var body: some View {
        VStack(spacing: 16) {
            // Tree header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tree.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !tree.treeDescription.isEmpty {
                        Text(tree.treeDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(tree.completionPercentage * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            ProgressView(value: tree.completionPercentage)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.green)
            
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
            
            // Add Node button
            Button(action: { showingAddNode = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    
                    Text("Add Node")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            
            // Tree visualization
            if let rootNode = tree.rootNodes.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tree Structure")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    NestedNodeView(node: rootNode) { node in
                        selectedNode = node
                        showingNodeDetail = true
                    }
                    .environment(\.levelHeightMap, levelHeights)
                    .onPreferenceChange(LevelHeightPreferenceKey.self) { heights in
                        levelHeights = heights
                    }
                    .frame(minHeight: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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