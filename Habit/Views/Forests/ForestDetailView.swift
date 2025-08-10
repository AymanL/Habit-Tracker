import SwiftUI

struct ForestDetailView: View {
    @ObservedObject var forest: Forest
    @EnvironmentObject var dataController: DataController
    @FetchRequest(
        entity: Forest.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Forest.creationDate_, ascending: false)]
    ) private var forests: FetchedResults<Forest>
    @State private var showingAddTree = false
    @State private var showingImportView = false
    @State private var selectedTree: SkillTree?
    @State private var showingTreeDetail = false
    @State private var currentTreeIndex = 0
    @State private var selectedForest: Forest?
    
    // Active forest is the currently selected one (falls back to the one passed in)
    private var activeForest: Forest { selectedForest ?? forest }

    var sortedTrees: [SkillTree] {
        getTreesSortedByOrder(activeForest)
    }
    
    var currentTree: SkillTree? {
        guard !sortedTrees.isEmpty, currentTreeIndex < sortedTrees.count else { return nil }
        return sortedTrees[currentTreeIndex]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with forest info
                ForestHeaderView(
                    forest: activeForest,
                    canNavigateForests: forests.count > 1,
                    onPreviousForest: previousForest,
                    onNextForest: nextForest
                )
                
                // Tree navigation and display
                if !sortedTrees.isEmpty {
                    ForestTreeNavigationView(
                        forest: activeForest,
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
            .if(Constants.debugSkillTreeUI) { view in
                view
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.yellow, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        Text("🟨 ScrollContent")
                            .font(.caption2)
                            .padding(2)
                            .background(Color.yellow.opacity(0.8))
                            .foregroundColor(.black)
                            .cornerRadius(3)
                            .padding(4)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { print("🟨 ScrollContent width: \(Int(geo.size.width))") }
                                .onChange(of: geo.size) { newSize in
                                    print("🟨 ScrollContent width updated: \(Int(newSize.width))")
                                }
                        }
                    )
            }
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
                EditSkillTreeView(forest: activeForest)
            }
        }
        .sheet(isPresented: $showingImportView) {
            ImportSingleTreeView(forest: activeForest)
        }
        .background(
            Group {
                if let tree = selectedTree {
                    NavigationLink(
                        destination: SkillTreeDetailView(skillTree: tree),
                        isActive: $showingTreeDetail
                    ) { EmptyView() }
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

    private func previousForest() {
        guard let currentIndex = forests.firstIndex(of: activeForest), !forests.isEmpty else { return }
        let newIndex = (currentIndex - 1 + forests.count) % forests.count
        selectedForest = forests[newIndex]
        currentTreeIndex = 0
    }

    private func nextForest() {
        guard let currentIndex = forests.firstIndex(of: activeForest), !forests.isEmpty else { return }
        let newIndex = (currentIndex + 1) % forests.count
        selectedForest = forests[newIndex]
        currentTreeIndex = 0
    }
}

// MARK: - Forest Header View
struct ForestHeaderView: View {
    @ObservedObject var forest: Forest
    let canNavigateForests: Bool
    let onPreviousForest: () -> Void
    let onNextForest: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Forest title brought back into the header area
                Text(forest.name_ ?? "Forest")
                    .font(.headline)
                    .fontWeight(.semibold)
                
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
            
            HStack(spacing: 8) {
                Button(action: onPreviousForest) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canNavigateForests)

                ProgressView(value: calculateForestCompletion(forest))
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.green)
                    .frame(maxWidth: .infinity)
                
                Button(action: onNextForest) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canNavigateForests)
            }
            
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
            // Current tree display
            if let tree = currentTree {
                ForestTreeDisplayView(
                    tree: tree,
                    canNavigate: totalTrees > 1,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onTreeTap: onTreeTap
                )
            }
        }
        .if(Constants.debugSkillTreeUI) { view in
            view
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    Text("🟦 TreeNav")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(3)
                        .padding(4)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { print("🟦 TreeNav width: \(Int(geo.size.width))") }
                            .onChange(of: geo.size) { newSize in
                                print("🟦 TreeNav width updated: \(Int(newSize.width))")
                            }
                    }
                )
        }
    }
}

// MARK: - Forest Tree Display View
struct ForestTreeDisplayView: View {
    @ObservedObject var tree: SkillTree
    let canNavigate: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onTreeTap: (SkillTree) -> Void
    @State private var selectedNode: SkillNode?
    @State private var showingNodeDetail = false
    @State private var showingAddNode = false
    @State private var levelHeights: [Int: CGFloat] = [:]
    
    var body: some View {
        VStack(spacing: 16) {
            // Tree header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tree.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    if !tree.treeDescription.isEmpty {
                        Text(tree.treeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Text("\(Int(tree.completionPercentage * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
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
                VStack(alignment: .leading, spacing: 8) {
                    NestedNodeView(node: rootNode) { node in
                        selectedNode = node
                        showingNodeDetail = true
                    } onNodeLongPress: { node in
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
                .frame(maxWidth: .infinity, alignment: .center)
                .if(Constants.debugSkillTreeUI) { view in
                    view
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.purple, lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            Text("🟪 TreeWrapper")
                                .font(.caption2)
                                .background(Color.purple.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(3)
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear { print("🟪 TreeWrapper width: \(Int(geo.size.width))") }
                                    .onChange(of: geo.size) { newSize in
                                        print("🟪 TreeWrapper width updated: \(Int(newSize.width))")
                                    }
                            }
                        )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .if(Constants.debugSkillTreeUI) { view in
            view
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.green, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    Text("🟩 TreeCard")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(3)
                        .padding(4)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { print("🟩 TreeCard width: \(Int(geo.size.width))") }
                            .onChange(of: geo.size) { newSize in
                                print("🟩 TreeCard width updated: \(Int(newSize.width))")
                            }
                    }
                )
        }
        .sheet(item: $selectedNode) { node in
            NavigationView {
                EditSkillNodeView(skillTree: tree, skillNode: node)
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