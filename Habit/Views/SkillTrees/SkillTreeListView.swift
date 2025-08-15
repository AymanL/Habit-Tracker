import SwiftUI

struct SkillTreeListView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddTree = false
    @State private var showingImportView = false
    @State private var currentTreeIndex = 0
    @State private var selectedNode: SkillNode?
    @State private var showingAddNode = false
    @State private var showingNodeDetail = false
    @State private var showingDeleteAlert = false
    @State private var treeToDelete: SkillTree?
    
    @FetchRequest(
        entity: SkillTree.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SkillTree.order_, ascending: true)]
    ) var skillTrees: FetchedResults<SkillTree>
    
    var sortedTrees: [SkillTree] {
        Array(skillTrees)
    }
    
    var currentTree: SkillTree? {
        guard !sortedTrees.isEmpty, currentTreeIndex < sortedTrees.count else { return nil }
        return sortedTrees[currentTreeIndex]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !sortedTrees.isEmpty, let tree = currentTree {
                        // Tree Navigation Header
                        SkillTreeNavigationView(
                            currentTree: tree,
                            currentIndex: currentTreeIndex,
                            totalTrees: sortedTrees.count,
                            onPrevious: {
                                if currentTreeIndex > 0 {
                                    currentTreeIndex -= 1
                                }
                            },
                            onNext: {
                                if currentTreeIndex < sortedTrees.count - 1 {
                                    currentTreeIndex += 1
                                }
                            },
                            onNodeTap: { node in
                                selectedNode = node
                                showingNodeDetail = true
                            },
                            onAddNode: {
                                showingAddNode = true
                            },
                            onDeleteTree: {
                                treeToDelete = tree
                                showingDeleteAlert = true
                            }
                        )
                    } else {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "tree.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Skill Trees")
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Text("Create your first skill tree to get started")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 100)
                    }
                }
                .padding()
            }
            .navigationTitle("Skill Trees")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingImportView = true }) {
                            Image(systemName: "doc.badge.plus")
                        }
                        
                        Button("Add") {
                            showingAddTree = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTree) {
                NavigationView {
                    EditSkillTreeView()
                }
            }
            .sheet(isPresented: $showingImportView) {
                ImportSkillTreeView()
            }
            .sheet(item: $selectedNode) { node in
                NavigationView {
                    EditSkillNodeView(skillTree: node.tree!, skillNode: node)
                }
            }
            .sheet(isPresented: $showingAddNode) {
                if let currentTree = sortedTrees.indices.contains(currentTreeIndex) ? sortedTrees[currentTreeIndex] : nil {
                    NavigationView {
                        EditSkillNodeView(skillTree: currentTree)
                    }
                }
            }
            .alert("Delete Skill Tree", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteCurrentTree()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let tree = treeToDelete {
                    Text("Are you sure you want to delete '\(tree.name)'? This action cannot be undone.")
                }
            }
        }
    }
    
    private func deleteCurrentTree() {
        guard let tree = treeToDelete else { return }
        
        // Adjust current index if necessary
        if currentTreeIndex >= sortedTrees.count - 1 && currentTreeIndex > 0 {
            currentTreeIndex -= 1
        }
        
        // Delete the tree
        dataController.delete(tree)
        dataController.save()
        
        // Reset state
        treeToDelete = nil
    }
}

// MARK: - Skill Tree Navigation View
struct SkillTreeNavigationView: View {
    @ObservedObject var currentTree: SkillTree
    let currentIndex: Int
    let totalTrees: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onNodeTap: (SkillNode) -> Void
    let onAddNode: () -> Void
    let onDeleteTree: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
                // Tree Header with Navigation
                VStack(spacing: 12) {
                    // Navigation controls
                    HStack {
                        Button(action: onPrevious) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(currentIndex > 0 ? .blue : .gray)
                        }
                        .disabled(currentIndex <= 0)
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text(currentTree.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text("\(currentIndex + 1) of \(totalTrees)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: onDeleteTree) {
                                Image(systemName: "trash")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: onNext) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(currentIndex < totalTrees - 1 ? .blue : .gray)
                            }
                            .disabled(currentIndex >= totalTrees - 1)
                        }
                    }
                    
                    // Tree description
                    if !currentTree.treeDescription.isEmpty {
                        Text(currentTree.treeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    
                    // Progress information
                    VStack(spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(currentTree.completedNodesCount)/\(currentTree.totalNodesCount) nodes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(currentTree.completionPercentage * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        ProgressView(value: currentTree.completionPercentage)
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(y: 1.5)
                    }
                    
                    // Add Node Button
                    Button(action: onAddNode) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.subheadline)
                            Text("Add Node")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Tree Visualization
                SkillTreeVisualizationView(skillTree: currentTree, onNodeTap: onNodeTap)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
        }
    }
}

#Preview {
    SkillTreeListView()
        .environmentObject(DataController.preview)
}